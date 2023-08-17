from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin

from block_header.block_header import (
    ChainState,
    fetch_block_header,
    validate_and_apply_block_header,
)

from block_header.median import TIMESTAMP_COUNT
from utils.utils import HASH_FELT_SIZE, UINT32


const CHAIN_STATE_SIZE = 50;
// The total outputs are the in and out state and the program hash
const OUTPUT_COUNT = CHAIN_STATE_SIZE * 2 + 1;
const PROGRAM_HASH_INDEX = OUTPUT_COUNT - 1;

// PUBLIC INPUTS LAYOUT (both prev_state and next_state)
//      [0]         block_height
//      [1..8]      best_block_hash
//      [9]         total_work
//      [10]        current_target
//      [11..21]    timestamps
//      [22]        epoch_start_time
//      [23..49]    mmr_roots
//  ---> total: 50 public inputs
//
namespace outputs {
    const BLOCK_HEIGHT = 0;
    const BEST_BLOCK_HASH = 1;
    const TOTAL_WORK = 9;
    const CURRENT_TARGET = 10;
    const TIMESTAMPS = 11;
    const EPOCH_START_TIME = 22;
    const MMR_ROOTS = 23;
}

func serialize_chain_state{output_ptr: felt*}(chain_state: ChainState) {
    serialize_word(chain_state.block_height);
    serialize_array(chain_state.best_block_hash, HASH_FELT_SIZE);
    serialize_word(chain_state.total_work);
    serialize_word(chain_state.current_target);
    serialize_array(chain_state.prev_timestamps, TIMESTAMP_COUNT);
    serialize_word(chain_state.epoch_start_time);
    return ();
}

func serialize_array{output_ptr: felt*}(array: felt*, array_len) {
    if (array_len == 0) {
        return ();
    }
    serialize_word([array]);
    serialize_array(array + 1, array_len - 1);
    return ();
}

// Convert a block hash into a felt
//
func block_hash_to_felt(block_hash: felt*) -> felt {
    // Validate that the hash's most significant uint32 chunk is zero
    // This guarantees that the hash fits into a felt.
    with_attr error_message("The hash's most significant uint32 chunk ({block_hash[7]}) is not zero.") {
        assert 0 = block_hash[7];
    }

    // Sum up the other 7 uint32 chunks of the hash into 1 felt
    let result = block_hash[0] * UINT32 ** 0 + 
                 block_hash[1] * UINT32 ** 1 + 
                 block_hash[2] * UINT32 ** 2 + 
                 block_hash[3] * UINT32 ** 3 + 
                 block_hash[4] * UINT32 ** 4 + 
                 block_hash[5] * UINT32 ** 5 + 
                 block_hash[6] * UINT32 ** 6;
    return result;
}

// Validates the next n block headers and returns a tuple of the final state and an array containing all block header pedersen hashes.
// The block header pedersen hashes are used to create a Merkle tree over all block headers of the batch
//
func validate_block_headers{
    range_check_ptr, bitwise_ptr: BitwiseBuiltin*, hash256_ptr: felt*, chain_state: ChainState
}(n, block_hashes: felt*) {
    if (n == 0) {
        return ();
    }
    alloc_locals;

    // Get the next block header
    let block_header = fetch_block_header(chain_state.block_height + 1);

    // Validate the block header and get the new state
    validate_and_apply_block_header(block_header);

    let block_hash = block_hash_to_felt(chain_state.best_block_hash);
    assert [block_hashes] = block_hash;

    return validate_block_headers(n - 1, block_hashes + 1);
}
