%builtins output pedersen range_check bitwise

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.serialize import serialize_word

from utils.utils import HASH_FELT_SIZE
from block_header.block_header import ChainState
from block_header.median import TIMESTAMP_COUNT

from utils.python_utils import setup_python_defs
from crypto.hash256 import finalize_hash256_block_header
from crypto.merkle_mountain_range import mmr_append_leaves, MMR_ROOTS_LEN
from utils.chain_state_utils import validate_block_headers, serialize_array, serialize_chain_state, block_hash_to_felt

func main{
    output_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    setup_python_defs();

    // initialize hash256_ptr
    let hash256_ptr: felt* = alloc();
    let hash256_ptr_start = hash256_ptr;

    // Read the previous state from the program input
    local block_height: felt;
    local total_work: felt;
    let best_block_hash : felt* = alloc();
    local current_target: felt;
    local epoch_start_time: felt;
    let prev_timestamps : felt* = alloc();
    let mmr_roots : felt* = alloc();
    local program_hash: felt;
    local batch_size: felt;

    %{
        ids.block_height = program_input["block_height"] if program_input["block_height"] != -1 else PRIME - 1
        ids.total_work = program_input["total_work"]
        segments.write_arg(ids.best_block_hash, felts_from_hash( program_input["best_block_hash"]) )
        ids.current_target = program_input["current_target"]
        ids.epoch_start_time = program_input["epoch_start_time"]
        segments.write_arg(ids.prev_timestamps, program_input["prev_timestamps"])
        ids.batch_size = program_input["batch_size"]
        segments.write_arg(ids.mmr_roots, felts_from_hex_strings( program_input["mmr_roots"] ) )
    %}

    // The ChainState of the previous state
    let chain_state = ChainState(
        block_height, 
        total_work, 
        best_block_hash, 
        current_target, 
        epoch_start_time, 
        prev_timestamps
    );

    // Output the previous state
    serialize_chain_state(chain_state);
    serialize_array(mmr_roots, MMR_ROOTS_LEN);

    // Validate all blocks in this batch and update the state
    let block_hashes: felt* = alloc();
    with hash256_ptr, chain_state {
        validate_block_headers(batch_size, block_hashes);
    }
    finalize_hash256_block_header(hash256_ptr_start, hash256_ptr);

    mmr_append_leaves{hash_ptr=pedersen_ptr, mmr_roots=mmr_roots}(block_hashes, batch_size);

    // Output the next state
    serialize_chain_state(chain_state);
    serialize_array(mmr_roots, MMR_ROOTS_LEN);
    // Padding zero such that NUM_OUTPUTS of the aggregate program and batch program are equal
    serialize_word(0);

    return ();
}
