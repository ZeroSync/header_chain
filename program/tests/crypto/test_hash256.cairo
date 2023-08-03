//
// To run only this test suite use:
// protostar test --cairo-path=./program/src target program/tests/crypto/*_hash256*
//
%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

from utils.python_utils import setup_python_defs
from utils.utils import assert_hashes_equal
from crypto.sha256_packed import BLOCK_SIZE
from crypto.hash256 import hash256_block_header, finalize_hash256_block_header
from block_header.block_header import fetch_block_header

const NUM_BLOCK_HEADERS = BLOCK_SIZE - 1;

@external
func test_hash256_block_header{range_check_ptr, bitwise_ptr: BitwiseBuiltin*}() {
    alloc_locals;
    setup_python_defs();
    
    // initialize hash256_ptr
    let hash256_ptr: felt* = alloc();
    let hash256_ptr_start = hash256_ptr;

    let block_header = fetch_block_header(0);

    with hash256_ptr {
        _test_hash256_block_header_loop(block_header, NUM_BLOCK_HEADERS);
    }

    // finalize hash256_ptr
    finalize_hash256_block_header(hash256_ptr_start, hash256_ptr);
    
    return ();
}

func _test_hash256_block_header_loop{
    range_check_ptr, bitwise_ptr: BitwiseBuiltin*, hash256_ptr: felt*
}(block_header: felt*, n) {
    if (n == 0) {
        return ();
    }

    alloc_locals;

    with hash256_ptr {
        let block_hash = hash256_block_header(block_header);
    }

    let (expected) = alloc();

    %{
        felts = hex_to_felt("000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f")
        def swap32(x):
            return (((x << 24) & 0xFF000000) |
                    ((x <<  8) & 0x00FF0000) |
                    ((x >>  8) & 0x0000FF00) |
                    ((x >> 24) & 0x000000FF))
        segments.write_arg(ids.expected, [swap32(word) for word in felts] [::-1])
    %}

    assert_hashes_equal(block_hash, expected);

    return _test_hash256_block_header_loop(block_header, n - 1);
}