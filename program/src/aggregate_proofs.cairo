%builtins output pedersen range_check bitwise

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.hash import HashBuiltin
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.serialize import serialize_word

from starkware.cairo.stark_verifier.air.layouts.recursive.public_verify import segments
from starkware.cairo.stark_verifier.core.stark import StarkProof
from starkware.cairo.stark_verifier.air.public_input import PublicInput, SegmentInfo
from starkware.cairo.stark_verifier.air.public_memory import AddrValue

from block_header.block_header import ChainState
from utils.utils import assert_hashes_equal, assert_mem_equal
from starkware.cairo.cairo_verifier.layouts.all_cairo.cairo_verifier import (
    verify_cairo_proof,
    extract_range,
)
from starkware.cairo.common.hash_state import hash_felts

from crypto.merkle_mountain_range import MMR_ROOTS_LEN
from block_header.median import TIMESTAMP_COUNT
from utils.utils import HASH_FELT_SIZE
from utils.chain_state_utils import (
    serialize_array,
    CHAIN_STATE_SIZE,
    OUTPUT_COUNT,
    PROGRAM_HASH_INDEX,
)

const BATCH_PROGRAM_HASH = 0x341b92f1ee4594687102b537a4219d5d56653456fab19d2edb2208b6cb584a2;

// PUBLIC INPUTS LAYOUT (both prev_state and next_state)
//  Initial state:
//      [0]         block_height
//      [1..8]      best_block_hash
//      [9]         total_work
//      [10]        current_target
//      [11..21]    timestamps
//      [22]        epoch_start_time
//      [23..49]    mmr_roots
//  End state (starting from offset 50):
//      [0]         block_height
//      [1..8]      best_block_hash
//      [9]         total_work
//      [10]        current_target
//      [11..21]    timestamps
//      [22]        epoch_start_time
//      [23..49]    mmr_roots
//  Program hash:
//      [100]       AGGREGATE_PROGRAM_HASH (0 if the program was a batch_program)
//
//  ---> CHAIN_STATE_SIZE = 50
//  ---> total public inputs: 101
func main{
    output_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    // 0. Read the aggregate program hash from a hint
    //
    local aggregate_program_hash;
    let prev_proof_mem: StarkProof* = alloc();
    let next_proof_mem: StarkProof* = alloc();
    local prev_proof: StarkProof* = prev_proof_mem;
    local next_proof: StarkProof* = next_proof_mem;
    %{
        ids.aggregate_program_hash = program_input["aggregate_program_hash"]
        segments.write_arg(ids.prev_proof.address_, [(int(x, 16) if x.startswith('0x') else ids.prev_proof.address_ + int(x)) for x in program_input["prev_proof"]])
        segments.write_arg(ids.next_proof.address_, [(int(x, 16) if x.startswith('0x') else ids.next_proof.address_ + int(x)) for x in program_input["next_proof"]])
    %}

    // 1. Verify the previous proof
    //
    let (prev_program, prev_program_len, prev_mem_values, prev_output_len) = verify_cairo_proof(prev_proof);
    assert prev_output_len = OUTPUT_COUNT;

// 2. Verify the next proof
    let (next_program, next_program_len, next_mem_values, next_output_len) = verify_cairo_proof(next_proof);
    assert next_output_len = OUTPUT_COUNT;
	
	// 3. Verify the program is a batch or aggregate program
	//
	// NOTE: To avoid redundant hashing of the program we only allow aggregating two programs of the same type.
	//		 So either both proofs are generated via the batch program or the aggregate program.
	//		 CAN NOT verify one batch program proof and an aggregate program proof at the same time!
    // Ensure both programs are equal
	assert 0 = next_program_len - prev_program_len;
	assert_mem_equal(prev_program, next_program, next_program_len);

	// Calculate the program hash
	let (program_hash) = hash_felts{hash_ptr=pedersen_ptr}(data=prev_program, length=next_program_len);
	
	// Ensure the program is either the batch program or the aggregate program.
    if (program_hash != BATCH_PROGRAM_HASH) {
        assert program_hash = aggregate_program_hash;
        assert prev_mem_values[PROGRAM_HASH_INDEX] = aggregate_program_hash;
        assert next_mem_values[PROGRAM_HASH_INDEX] = aggregate_program_hash;
    } else {
		// Batch program outputs a padding zero instead of its hash
        assert prev_mem_values[PROGRAM_HASH_INDEX] = 0;
		assert next_mem_values[PROGRAM_HASH_INDEX] = 0;
    }

    // 4. Verify the proofs fit together
	//
    // Ensure that the next_state of the previous proof is the prev_state of the next proof
	assert_mem_equal(prev_mem_values + CHAIN_STATE_SIZE, next_mem_values, CHAIN_STATE_SIZE);

    // Output the prev_state of the prev_proof
    serialize_array(prev_mem_values, CHAIN_STATE_SIZE);

    // Output the next_state of the next_proof
    serialize_array(next_mem_values + CHAIN_STATE_SIZE, CHAIN_STATE_SIZE);

    // Output the aggregate program hash
    serialize_word(aggregate_program_hash);
    return ();
}
