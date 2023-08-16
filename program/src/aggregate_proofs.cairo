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
from utils.utils import assert_hashes_equal
from starkware.cairo.cairo_verifier.layouts.all_cairo.cairo_verifier import (
    verify_cairo_proof,
    extract_range,
)

from crypto.merkle_mountain_range import MMR_ROOTS_LEN
from block_header.median import TIMESTAMP_COUNT
from utils.utils import HASH_FELT_SIZE
from utils.chain_state_utils import (
    serialize_array,
    CHAIN_STATE_SIZE,
    OUTPUT_COUNT,
    PROGRAM_HASH_INDEX,
)

const BATCH_PROGRAM_HASH = 0x1ecdc2d98b50566369e224c36257d955a0a9a9fd62df95951f5713ab7434268;

func main{
    output_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    // 0. Read the aggregate program hash from a hint
    //
    local AGGREGATE_PROGRAM_HASH;
    let prev_proof_mem: StarkProof* = alloc();
    let next_proof_mem: StarkProof* = alloc();
    local prev_proof: StarkProof* = prev_proof_mem;
    local next_proof: StarkProof* = next_proof_mem;
    %{
        ids.AGGREGATE_PROGRAM_HASH = program_input["aggregate_program_hash"]
        segments.write_arg(ids.prev_proof.address_, [(int(x, 16) if x.startswith('0x') else ids.prev_proof.address_ + int(x)) for x in program_input["prev_proof"]])
        segments.write_arg(ids.next_proof.address_, [(int(x, 16) if x.startswith('0x') else ids.next_proof.address_ + int(x)) for x in program_input["next_proof"]])
    %}

    // 1. Verify the previous proof
    //
    let (prev_program_hash, prev_mem_values, prev_output_len) = verify_cairo_proof(prev_proof);
    assert prev_output_len = OUTPUT_COUNT;

    // Ensure the program is either the batch program or the aggregate program
    if (prev_program_hash != BATCH_PROGRAM_HASH) {
        assert prev_program_hash = AGGREGATE_PROGRAM_HASH;
        assert prev_mem_values[PROGRAM_HASH_INDEX] = AGGREGATE_PROGRAM_HASH;
    } else {
        %{ print("This is a batch proof") %}
        assert prev_mem_values[PROGRAM_HASH_INDEX] = 0;  // Batch program doesnt output its hash but only a padding zero
    }

    // 2. Verify the next program
    //
    let (next_program_hash, next_mem_values, next_output_len) = verify_cairo_proof(next_proof);
    assert next_output_len = OUTPUT_COUNT;

    // Ensure the program is either the batch program or the aggregate program
    if (next_program_hash != BATCH_PROGRAM_HASH) {
        assert AGGREGATE_PROGRAM_HASH = next_program_hash;
        assert next_mem_values[PROGRAM_HASH_INDEX] = AGGREGATE_PROGRAM_HASH;
    } else {
        %{ print("This is a batch proof") %}
        assert next_mem_values[PROGRAM_HASH_INDEX] = 0;  // Batch program doesnt output its hash but only a padding zero
    }

    // 3. Verify the proofs fit together
    //
    
    // Ensure that the next_state of the previous proof is the prev_state of the next proof
    verify_chain_states(prev_mem_values + CHAIN_STATE_SIZE, next_mem_values);

    // Output the initial state of the prev_proof
    serialize_array(prev_mem_values, CHAIN_STATE_SIZE);

    // Output the end_state of the next_proof
    serialize_array(next_mem_values + CHAIN_STATE_SIZE, CHAIN_STATE_SIZE);

    // Output the aggregate program hash
    serialize_word(AGGREGATE_PROGRAM_HASH);
    return ();
}

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
//  ---> PROGRAM_HASH_INDEX = 100
func verify_chain_states(prev_mem_values: felt*, next_mem_values: felt*) {
    assert 0 = prev_mem_values[0] - next_mem_values[0];
    assert 0 = prev_mem_values[1] - next_mem_values[1];
    assert 0 = prev_mem_values[2] - next_mem_values[2];
    assert 0 = prev_mem_values[3] - next_mem_values[3];
    assert 0 = prev_mem_values[4] - next_mem_values[4];
    assert 0 = prev_mem_values[5] - next_mem_values[5];
    assert 0 = prev_mem_values[6] - next_mem_values[6];
    assert 0 = prev_mem_values[7] - next_mem_values[7];
    assert 0 = prev_mem_values[8] - next_mem_values[8];
    assert 0 = prev_mem_values[9] - next_mem_values[9];
    assert 0 = prev_mem_values[10] - next_mem_values[10];
    assert 0 = prev_mem_values[11] - next_mem_values[11];
    assert 0 = prev_mem_values[12] - next_mem_values[12];
    assert 0 = prev_mem_values[13] - next_mem_values[13];
    assert 0 = prev_mem_values[14] - next_mem_values[14];
    assert 0 = prev_mem_values[15] - next_mem_values[15];
    assert 0 = prev_mem_values[16] - next_mem_values[16];
    assert 0 = prev_mem_values[17] - next_mem_values[17];
    assert 0 = prev_mem_values[18] - next_mem_values[18];
    assert 0 = prev_mem_values[19] - next_mem_values[19];
    assert 0 = prev_mem_values[20] - next_mem_values[20];
    assert 0 = prev_mem_values[21] - next_mem_values[21];
    assert 0 = prev_mem_values[22] - next_mem_values[22];
    assert 0 = prev_mem_values[23] - next_mem_values[23];
    assert 0 = prev_mem_values[24] - next_mem_values[24];
    assert 0 = prev_mem_values[25] - next_mem_values[25];
    assert 0 = prev_mem_values[26] - next_mem_values[26];
    assert 0 = prev_mem_values[27] - next_mem_values[27];
    assert 0 = prev_mem_values[28] - next_mem_values[28];
    assert 0 = prev_mem_values[29] - next_mem_values[29];
    assert 0 = prev_mem_values[30] - next_mem_values[30];
    assert 0 = prev_mem_values[31] - next_mem_values[31];
    assert 0 = prev_mem_values[32] - next_mem_values[32];
    assert 0 = prev_mem_values[33] - next_mem_values[33];
    assert 0 = prev_mem_values[34] - next_mem_values[34];
    assert 0 = prev_mem_values[35] - next_mem_values[35];
    assert 0 = prev_mem_values[36] - next_mem_values[36];
    assert 0 = prev_mem_values[37] - next_mem_values[37];
    assert 0 = prev_mem_values[38] - next_mem_values[38];
    assert 0 = prev_mem_values[39] - next_mem_values[39];
    assert 0 = prev_mem_values[40] - next_mem_values[40];
    assert 0 = prev_mem_values[41] - next_mem_values[41];
    assert 0 = prev_mem_values[42] - next_mem_values[42];
    assert 0 = prev_mem_values[43] - next_mem_values[43];
    assert 0 = prev_mem_values[44] - next_mem_values[44];
    assert 0 = prev_mem_values[45] - next_mem_values[45];
    assert 0 = prev_mem_values[46] - next_mem_values[46];
    assert 0 = prev_mem_values[47] - next_mem_values[47];
    assert 0 = prev_mem_values[48] - next_mem_values[48];
    assert 0 = prev_mem_values[49] - next_mem_values[49];
    return ();
}
