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
