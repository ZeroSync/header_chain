%builtins output pedersen range_check bitwise

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.memcpy import memcpy

from starkware.cairo.cairo_verifier.layouts.all_cairo.cairo_verifier import verify_cairo_proof
from starkware.cairo.stark_verifier.core.stark import StarkProof
from starkware.cairo.common.hash_state import hash_felts

from utils.utils import HASH_FELT_SIZE
from utils.python_utils import setup_python_defs
from block_header.block_header import ChainState, validate_and_apply_block_header
from block_header.median import TIMESTAMP_COUNT

from crypto.hash256 import finalize_hash256_block_header
from crypto.merkle_mountain_range import mmr_append_leaves, MMR_ROOTS_LEN
from utils.chain_state_utils import (
    validate_block_headers,
    serialize_array,
    serialize_chain_state,
    outputs,
    CHAIN_STATE_SIZE,
    OUTPUT_COUNT,
    PROGRAM_HASH_INDEX,
)

const AGGREGATE_PROGRAM_HASH = 0x92559bd41c8951b211c4cdfcb85540c2fd29ea60d255309658b933d4fbe213;
const BATCH_PROGRAM_HASH = 0x667df2c6ce371965ec67a1761ad9989e791a41a9c62b24b8bcb3137feb49888;

func main{
    output_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    setup_python_defs();

    // initialize hash256_ptr
    let hash256_ptr: felt* = alloc();
    let hash256_ptr_start = hash256_ptr;

    // 0. Read the increment program hash from a hint
    //
    local increment_program_hash;
    let prev_proof_mem: StarkProof* = alloc();
    local prev_proof: StarkProof* = prev_proof_mem;
    %{
        ids.increment_program_hash = program_input["increment_program_hash"]
        segments.write_arg(ids.prev_proof.address_, [(int(x, 16) if x.startswith('0x') else ids.prev_proof.address_ + int(x)) for x in program_input["prev_proof"]])
    %}

    // 1. Read and verify the previous proof
    //
    let (prev_program, prev_program_len, prev_mem_values, prev_output_len) = verify_cairo_proof(prev_proof);
    assert prev_output_len = OUTPUT_COUNT;
	let (prev_program_hash) = hash_felts{hash_ptr=pedersen_ptr}(prev_program, prev_program_len);

    // Ensure the previous program is either the "aggregate", "batch", or "increment" program
    if (AGGREGATE_PROGRAM_HASH != prev_program_hash) {
        if (BATCH_PROGRAM_HASH != prev_program_hash) {
            assert increment_program_hash = prev_program_hash;
            assert increment_program_hash = prev_mem_values[PROGRAM_HASH_INDEX];
        }
    }


    // 2. Increment the previous proof with a next batch
    //
    // Parse the ChainState of the previous state from the previous proof's memory
    let chain_state = ChainState(
        block_height = prev_mem_values[outputs.BLOCK_HEIGHT],
        total_work = prev_mem_values[outputs.TOTAL_WORK],
        best_block_hash = prev_mem_values + outputs.BEST_BLOCK_HASH,
        current_target = prev_mem_values[outputs.CURRENT_TARGET],
        epoch_start_time = prev_mem_values[outputs.EPOCH_START_TIME],
        prev_timestamps = prev_mem_values + outputs.TIMESTAMPS
    );

    // The previous roots of the Merkle mountain range
    let mmr_roots: felt* = prev_mem_values + outputs.MMR_ROOTS;

    // Output the previous state
    serialize_chain_state(chain_state);
    serialize_array(mmr_roots, MMR_ROOTS_LEN);


    // Validate all block headers in this batch and update the state
    //

    // Read the previous state from the program input
    local batch_size: felt;
    %{ ids.batch_size = program_input["batch_size"] %}

    // Initialize hash256 pointer
    let hash256_ptr: felt* = alloc();
    let hash256_ptr_start = hash256_ptr;

    // Validate each block header
    let block_hashes: felt* = alloc();
    with hash256_ptr, chain_state {
        validate_block_headers(batch_size, block_hashes);
    }
    finalize_hash256_block_header(hash256_ptr_start, hash256_ptr);
    mmr_append_leaves{hash_ptr=pedersen_ptr, mmr_roots=mmr_roots}(block_hashes, batch_size);

    // Output the next state
    serialize_chain_state(chain_state);
    serialize_array(mmr_roots, MMR_ROOTS_LEN);
    // Padding zero such that NUM_OUTPUTS of the increment program and batch program are equal
    serialize_word(increment_program_hash);

    return ();
}
