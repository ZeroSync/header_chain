from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

from crypto.hash_utils import HASH_SIZE
from crypto.sha256 import compute_sha256

// Computes double sha256
//
func hash256{range_check_ptr, sha256_ptr: felt*}(
    input: felt*, byte_size: felt
) -> felt* {
    let hash_first_round = compute_sha256(input, byte_size);
    let hash = compute_sha256(hash_first_round, HASH_SIZE);
    return hash;
}
