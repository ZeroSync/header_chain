// Serialization Library for Reading and Writing Byte Streams
//
// A byte stream is represented as an array of uint32 because
// the sha256 hash function works on 32-bit words, and feeding
// byte streams into the sha256 function is our main reason for
// serializing any block data.
//

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_not_zero, assert_le, assert_le_felt
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256

// Swap the endianness of an uint32
func byteswap32{bitwise_ptr: BitwiseBuiltin*}(uint32) -> felt {
    alloc_locals;
    assert bitwise_ptr[0].x = uint32;
    assert bitwise_ptr[0].y = 0xFF00FF00;
    assert bitwise_ptr[1].x = bitwise_ptr[0].x_and_y / 2 ** 8 + (uint32 - bitwise_ptr[0].x_and_y) *
        2 ** 8;
    assert bitwise_ptr[1].y = 0xFFFF0000;
    let uint32_endian = bitwise_ptr[1].x_and_y / 2 ** 16 + (
        bitwise_ptr[1].x - bitwise_ptr[1].x_and_y
    ) * 2 ** 16;
    let bitwise_ptr = bitwise_ptr + BitwiseBuiltin.SIZE * 2;
    return uint32_endian;
}

// The base for byte-wise shifts via multiplication and integer division
const BYTE = 2 ** 8;
const UINT32 = 2 ** 32;

// The byte sizes of Uint8, Uint16, Uint32, and Uint64
const UINT8_SIZE = 1;
const UINT32_SIZE = 4;
const UINT256_SIZE = 32;

struct Reader {
    cur: felt,
    buf: felt,
    ptr: felt*,
}

func init_reader(ptr: felt*) -> Reader {
    let reader = Reader(1, 0, ptr);
    return reader;
}

// Read a byte from the reader
func read_uint8{reader: Reader, bitwise_ptr: BitwiseBuiltin*}() -> felt {
    alloc_locals;
    if (reader.cur == 1) {
        // The Reader is empty, so we read from the head, return the first byte,
        // and copy the remaining three bytes into the Reader's payload.
        // Ensure only lowest bits set
        assert [bitwise_ptr].x = [reader.ptr];
        assert [bitwise_ptr].y = 0xFFFFFFFF;
        tempvar reader_tmp = Reader(UINT32, [bitwise_ptr].x_and_y, reader.ptr + 1);
        tempvar bitwise_ptr = bitwise_ptr + BitwiseBuiltin.SIZE;
    } else {
        // The Reader is not empty. So we read the first byte from its payload
        // and continue with the remaining bytes.
        tempvar reader_tmp = reader;
        tempvar bitwise_ptr = bitwise_ptr;
    }
    let cur = reader_tmp.cur / BYTE;
    assert [bitwise_ptr].x = reader_tmp.buf;
    assert [bitwise_ptr].y = reader_tmp.cur - cur;
    let res = [bitwise_ptr].x_and_y / cur;
    let buf = reader_tmp.buf - [bitwise_ptr].x_and_y;
    let reader = Reader(cur, buf, reader_tmp.ptr);
    let bitwise_ptr = bitwise_ptr + BitwiseBuiltin.SIZE;
    return res;
}

// Read 32-bit integer from our usual 32-bit reader
func read_uint32{reader: Reader, bitwise_ptr: BitwiseBuiltin*}() -> felt {
    alloc_locals;
    let uint32_endian = read_uint32_endian();
    let uint32 = byteswap32(uint32_endian);
    return uint32;
}

func read_uint32_endian{reader: Reader, bitwise_ptr: BitwiseBuiltin*}() -> felt {
    alloc_locals;
    // Ensure only lowest bits set
    assert [bitwise_ptr].x = [reader.ptr];
    assert [bitwise_ptr].y = 0xFFFFFFFF;
    local buf_64 = reader.buf * UINT32 + [bitwise_ptr].x_and_y;
    let bitwise_ptr = bitwise_ptr + BitwiseBuiltin.SIZE;
    assert [bitwise_ptr].x = buf_64;
    assert [bitwise_ptr].y = 0xFFFFFFFF * reader.cur;
    let uint32_endian = [bitwise_ptr].x_and_y / reader.cur;
    let reader = Reader(reader.cur, buf_64 - [bitwise_ptr].x_and_y, reader.ptr + 1);
    let bitwise_ptr = bitwise_ptr + BitwiseBuiltin.SIZE;
    return uint32_endian;
}

// Read an array of 32-bit integers from our usual 32-bit reader
func read_bytes{reader: Reader, bitwise_ptr: BitwiseBuiltin*}(size) -> felt* {
    alloc_locals;
    let (ptr) = alloc();
    let writer: Writer = init_writer(ptr);

    assert [bitwise_ptr].x = size;
    assert [bitwise_ptr].y = 0xFFFFFFFC;
    let n_words = [bitwise_ptr].x_and_y / UINT32_SIZE;
    let n_bytes = size - [bitwise_ptr].x_and_y;
    let bitwise_ptr = bitwise_ptr + BitwiseBuiltin.SIZE;

    with writer, reader {
        read_write_words(n_words);
        read_write_bytes(n_bytes);
    }

    let buf_endian = byteswap32(writer.buf);
    let writer = Writer(writer.cur, buf_endian, writer.ptr);

    flush_writer(writer);
    return ptr;
}

func read_bytes_endian{reader: Reader, bitwise_ptr: BitwiseBuiltin*}(size) -> felt* {
    alloc_locals;
    let (ptr) = alloc();
    let writer: Writer = init_writer(ptr);

    assert [bitwise_ptr].x = size;
    assert [bitwise_ptr].y = 0xFFFFFFFC;
    let n_words = [bitwise_ptr].x_and_y / UINT32_SIZE;
    let n_bytes = size - [bitwise_ptr].x_and_y;
    let bitwise_ptr = bitwise_ptr + BitwiseBuiltin.SIZE;

    with writer, reader {
        read_write_words_endian(n_words);
        read_write_bytes(n_bytes);
    }

    flush_writer(writer);
    return ptr;
}

func read_hash{reader: Reader, bitwise_ptr: BitwiseBuiltin*}() -> felt* {
    return read_bytes_endian(UINT256_SIZE);
}


struct Writer {
    cur: felt,
    buf: felt,
    ptr: felt*,
}

func init_writer(ptr: felt*) -> Writer {
    let writer = Writer(UINT32, 0, ptr);
    return writer;
}

func read_write_words{writer: Writer, reader: Reader, bitwise_ptr: BitwiseBuiltin*}(n_words) {
    if (n_words == 0) {
        return ();
    }
    alloc_locals;
    assert [bitwise_ptr].x = [reader.ptr];
    assert [bitwise_ptr].y = 0xFFFFFFFF;
    local buf_64 = reader.buf * UINT32 + [bitwise_ptr].x_and_y;
    let bitwise_ptr = bitwise_ptr + BitwiseBuiltin.SIZE;
    assert [bitwise_ptr].x = buf_64;
    assert [bitwise_ptr].y = 0xFFFFFFFF * reader.cur;
    let word_endian = [bitwise_ptr].x_and_y / reader.cur;
    let reader = Reader(reader.cur, buf_64 - [bitwise_ptr].x_and_y, reader.ptr + 1);
    let bitwise_ptr = bitwise_ptr + BitwiseBuiltin.SIZE;
    let word = byteswap32(word_endian);
    assert [bitwise_ptr].x = writer.buf * UINT32 / writer.cur + word;
    assert [bitwise_ptr].y = 0xFFFFFFFF * UINT32 / writer.cur;
    assert [writer.ptr] = [bitwise_ptr].x_and_y * writer.cur / UINT32;
    let diff = word - [bitwise_ptr].x_and_y;
    let bitwise_ptr = bitwise_ptr + BitwiseBuiltin.SIZE;
    let writer = Writer(writer.cur, writer.buf * UINT32 + diff * writer.cur, writer.ptr + 1);
    read_write_words(n_words - 1);
    return ();
}

func read_write_words_endian{writer: Writer, reader: Reader, bitwise_ptr: BitwiseBuiltin*}(
    n_words
) {
    if (n_words == 0) {
        return ();
    }
    alloc_locals;
    assert [bitwise_ptr].x = [reader.ptr];
    assert [bitwise_ptr].y = 0xFFFFFFFF;
    local buf_64 = reader.buf * UINT32 + [bitwise_ptr].x_and_y;
    let bitwise_ptr = bitwise_ptr + BitwiseBuiltin.SIZE;
    assert [bitwise_ptr].x = buf_64;
    assert [bitwise_ptr].y = 0xFFFFFFFF * reader.cur;
    let word_endian = [bitwise_ptr].x_and_y / reader.cur;
    let reader = Reader(reader.cur, buf_64 - [bitwise_ptr].x_and_y, reader.ptr + 1);
    let bitwise_ptr = bitwise_ptr + BitwiseBuiltin.SIZE;
    assert [bitwise_ptr].x = writer.buf * UINT32 / writer.cur + word_endian;
    assert [bitwise_ptr].y = 0xFFFFFFFF * UINT32 / writer.cur;
    assert [writer.ptr] = [bitwise_ptr].x_and_y * writer.cur / UINT32;
    let diff = word_endian - [bitwise_ptr].x_and_y;
    let bitwise_ptr = bitwise_ptr + BitwiseBuiltin.SIZE;
    let writer = Writer(writer.cur, writer.buf * UINT32 + diff * writer.cur, writer.ptr + 1);
    read_write_words_endian(n_words - 1);
    return ();
}

// Any unwritten data in the writer's temporary memory is written to the writer.
// NOTE: Once you flushed continue writing will cause an error
func flush_writer(writer: Writer) {
    if (writer.cur == UINT32) {
        return ();
    }
    assert [writer.ptr] = writer.buf;
    return ();
}

func read_write_bytes{writer: Writer, reader: Reader, bitwise_ptr: BitwiseBuiltin*}(n_bytes) {
    if (n_bytes == 0) {
        return ();
    }
    alloc_locals;
    if (reader.cur == 1) {
        // Ensure only lowest bits set
        assert [bitwise_ptr].x = [reader.ptr];
        assert [bitwise_ptr].y = 0xFFFFFFFF;
        tempvar reader_tmp = Reader(UINT32, [bitwise_ptr].x_and_y, reader.ptr + 1);
        tempvar bitwise_ptr = bitwise_ptr + BitwiseBuiltin.SIZE;
    } else {
        tempvar reader_tmp = reader;
        tempvar bitwise_ptr = bitwise_ptr;
    }
    assert [bitwise_ptr].x = reader_tmp.buf;
    assert [bitwise_ptr].y = reader_tmp.cur - reader_tmp.cur / BYTE;
    let byte = [bitwise_ptr].x_and_y / (reader_tmp.cur / BYTE);
    let buf = reader_tmp.buf - [bitwise_ptr].x_and_y;
    let reader = Reader(reader_tmp.cur / BYTE, buf, reader_tmp.ptr);
    let bitwise_ptr = bitwise_ptr + BitwiseBuiltin.SIZE;
    if (writer.cur == BYTE) {
        assert [writer.ptr] = writer.buf + byte;
        tempvar writer = Writer(UINT32, 0, writer.ptr + 1);
    } else {
        tempvar writer = Writer(
            writer.cur / BYTE, writer.buf + byte * writer.cur / BYTE, writer.ptr
        );
    }
    read_write_bytes(n_bytes - 1);
    return ();
}
