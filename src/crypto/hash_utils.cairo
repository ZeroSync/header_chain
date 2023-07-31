from utils.serialize import UINT32_SIZE

const HASH_FELT_SIZE = 8;
const HASH_SIZE = HASH_FELT_SIZE * UINT32_SIZE;

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