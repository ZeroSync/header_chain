//
// To run only this test suite use:
// protostar test --cairo-path=./src target tests/test_merkle_mountain_range.cairo
//
%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.memset import memset
from crypto.merkle_mountain_range import mmr_append, mmr_append_leaves, MMR_ROOTS_LEN

@external
func test_mmr_basics{range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    let (mmr_roots) = alloc();
    memset(mmr_roots, 0, MMR_ROOTS_LEN);

    mmr_append{hash_ptr=pedersen_ptr, mmr_roots=mmr_roots}(0x111111111111111111111111);
    assert 0x111111111111111111111111 = mmr_roots[0];

    mmr_append{hash_ptr=pedersen_ptr, mmr_roots=mmr_roots}(0x222222222222222222222222);
    assert 0 = mmr_roots[0];
    assert 0x1b586e993478db71562f0cfe2ad81ccc463b0d18e64bde2fc825530714d8328 = mmr_roots[1];

    mmr_append{hash_ptr=pedersen_ptr, mmr_roots=mmr_roots}(0x333333333333333333333333);
    assert 0x333333333333333333333333 = mmr_roots[0];
    assert 0x1b586e993478db71562f0cfe2ad81ccc463b0d18e64bde2fc825530714d8328 = mmr_roots[1];

    mmr_append{hash_ptr=pedersen_ptr, mmr_roots=mmr_roots}(0x444444444444444444444444);
    assert 0 = mmr_roots[0];
    assert 0 = mmr_roots[1];
    assert 0x155d0053a90471bdcccd6f93c7bcea38a8e4dddb190077568fb8514cf9f3392 = mmr_roots[2];


    let (leaves) = alloc();
    assert leaves[0] = 42;
    assert leaves[1] = 43;
    assert leaves[2] = 44;
    assert leaves[3] = 45;
    let n_leaves = 4;
    mmr_append_leaves{hash_ptr=pedersen_ptr, mmr_roots=mmr_roots}(leaves, 4);

    return ();
}
