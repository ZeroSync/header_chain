from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import split_felt

// The base for byte-wise shifts via multiplication and integer division
const BYTE = 2 ** 8;
const UINT16 = 2 ** 16;
const UINT32 = 2 ** 32;

// The byte size of Uint32
const UINT32_SIZE = 4;

// The felt size of a hash
const HASH_FELT_SIZE = 8;

// Swap the endianness of an uint32
//
func byteswap32{bitwise_ptr: BitwiseBuiltin*}(uint32) -> felt {
    assert bitwise_ptr[0].x = uint32;
    assert bitwise_ptr[0].y = 0xFF00FF00;
    assert bitwise_ptr[1].x = bitwise_ptr[0].x_and_y / BYTE + (uint32 - bitwise_ptr[0].x_and_y) *
        BYTE;
    assert bitwise_ptr[1].y = 0xFFFF0000;
    let uint32_endian = bitwise_ptr[1].x_and_y / UINT16 + (bitwise_ptr[1].x - bitwise_ptr[1].x_and_y) *
        UINT16;
    let bitwise_ptr = bitwise_ptr + BitwiseBuiltin.SIZE * 2;
    return uint32_endian;
}


// Assert equality of two hashes represented as an array of 8 x Uint32
//
func assert_hashes_equal(hash1: felt*, hash2: felt*) {
    // We're doing some odd gymnastics here,
    // because in Cairo it isn't straight-forward to determine if a variable is uninitialized.
    // The hack `assert 0 = a - b` ensures that both `a` and `b` are initialized indeed.
    assert 0 = hash1[0] - hash2[0];
    assert 0 = hash1[1] - hash2[1];
    assert 0 = hash1[2] - hash2[2];
    assert 0 = hash1[3] - hash2[3];
    assert 0 = hash1[4] - hash2[4];
    assert 0 = hash1[5] - hash2[5];
    assert 0 = hash1[6] - hash2[6];
    assert 0 = hash1[7] - hash2[7];
    return ();
}

func assert_mem_equal(ptr_a: felt*, ptr_b: felt*, len) {
	if (len == 0) {
		return ();
	}
	assert 0 = ptr_a[0] - ptr_b[0];
	return assert_mem_equal(&ptr_a[1],&ptr_b[1], len - 1);
}


// Convert a felt to a Uint256
//
func felt_to_uint256{range_check_ptr}(value) -> Uint256 {
    let (high, low) = split_felt(value);
    let value256 = Uint256(low, high);
    return value256;
}
