//
// To run only this test suite use:
// protostar test --cairo-path=./src target tests/utils/test_serialize.cairo
//

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from crypto.hash_utils import assert_hashes_equal
from utils.serialize import (
    init_reader,
    read_uint8,
    read_uint32,
    read_bytes_endian
)

@external
func test_read_uint8{bitwise_ptr: BitwiseBuiltin*}() {
    alloc_locals;

    let reader = init_reader( new (0x01020304, 0x05000000) );

    with reader {
        let uint8_1 = read_uint8();
        let uint8_2 = read_uint8();
        let uint8_3 = read_uint8();
        let uint8_4 = read_uint8();
        let uint8_5 = read_uint8();
    }
    assert uint8_1 = 0x01;
    assert uint8_2 = 0x02;
    assert uint8_3 = 0x03;
    assert uint8_4 = 0x04;
    assert uint8_5 = 0x05;

    return ();
}



@external
func test_read_uint32{bitwise_ptr: BitwiseBuiltin*}() {
    alloc_locals;

    let reader = init_reader( new (0x01020304) );

    with reader {
        let uint32 = read_uint32();
    }
    assert uint32 = 0x04030201;

    return ();
}



@external
func test_read_bytes_endian{bitwise_ptr: BitwiseBuiltin*}() {
    alloc_locals;

    let reader = init_reader( new (0x01020304, 0x05060708, 0x090a0b0c,
                                   0x0d0e0f10, 0x11121314, 0x15161718) );

    with reader {
        let bytes3 = read_bytes_endian(3);
        let bytes5 = read_bytes_endian(5);
        let bytes6 = read_bytes_endian(6);
        let bytes7 = read_bytes_endian(7);
    }

    assert 0x01020300 = bytes3[0];

    assert 0x04050607 = bytes5[0];
    assert 0x08000000 = bytes5[1];

    assert 0x090a0b0c = bytes6[0];
    assert 0x0d0e0000 = bytes6[1];

    assert 0x0f101112 = bytes7[0];
    assert 0x13141500 = bytes7[1];

    return ();
}


@external
func test_read_uint32_overflow{bitwise_ptr: BitwiseBuiltin*}() {
    alloc_locals;
    
    let reader = init_reader( new (0x05010203ff) );

    with reader {
        let uint32 = read_uint32();
    }

    assert 0xff030201 = uint32;

    return ();
}

