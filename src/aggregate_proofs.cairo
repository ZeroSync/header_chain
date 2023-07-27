%builtins output pedersen range_check ecdsa bitwise ec_op

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.hash import HashBuiltin
from starkware.cairo.common.memcpy import memcpy

from block_header.block_header import ChainState
from crypto.hash_utils import assert_hashes_equal
from stark_verifier.stark_verifier import read_and_verify_stark_proof

from headers_chain_proof.merkle_mountain_range import MMR_ROOTS_LEN
from block_header.median import TIMESTAMP_COUNT
from crypto.hash_utils import HASH_FELT_SIZE

const BATCH_PROGRAM_HASH = 0;
const OUTPUTS_COUNT = 52;
const PROGRAM_HASH_INDEX = OUTPUTS_COUNT - 2;


func main{
    output_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    ecdsa_ptr,
    bitwise_ptr: BitwiseBuiltin*,
    ec_op_ptr,
}(){

    /// 0. Read the aggregate program hash from a hint
    // TODO: implement me
    local AGGREGATE_PROGRAM_HASH;
    %{
        ids.AGGREGATE_PROGRAM_HASH = 0
    %}

    /// 1. Read and verify the previous proof
    // Read the previous proof from a hint
    // TODO: implement me

    // Verify the previous proof
    // TODO: implement me
    let prev_mem_values = alloc();
    let prev_program_hash = 0;

    // Ensure the program is either the batch program or the aggregate program
    if (prev_program_hash != BATCH_PROGRAM_HASH){
        assert prev_program_hash = AGGREGATE_PROGRAM_HASH;
        assert prev_mem_values[PROGRAM_HASH_INDEX] = AGGREGATE_PROGRAM_HASH;
    }


    /// 2. Read and verify the next proof
    // Read the next proof from a hint
    // TODO: implement me
    
    // Verify the next proof
    let next_mem_values = alloc();
    let next_program_hash = 0;

    // Ensure the program is either the batch program or the aggregate program
    if (next_program_hash != BATCH_PROGRAM_HASH){
        assert next_program_hash = AGGREGATE_PROGRAM_HASH;
        assert next_mem_values[PROGRAM_HASH_INDEX] = AGGREGATE_PROGRAM_HASH;
    }


    /// 3. Verify the proofs fit together
    // Ensure that the next_state of the previous proof is the prev_state of the next proof
    verify_chain_states(prev_mem_values + OUTPUTS_COUNT, next_mem_values);

    // Output the prev_state of the prev_proof (except for the program hash)
    serialize_array(prev_mem_values, OUTPUTS_COUNT - 1);

    // Output the next_state of the next_proof (except for the program hash)
    serialize_array(next_mem_values + OUTPUTS_COUNT, OUTPUTS_COUNT - 1);

    // Output the aggregate program hash
    serialize_word(AGGREGATE_PROGRAM_HASH);
}


// PUBLIC INPUTS LAYOUT (both prev_state and next_state)
//      [0]         block_height
//      [1..8]      best_block_hash 
//      [9]         total_work
//      [10]        current_target
//      [11..21]    timestamps
//      [22]        epoch_start_time
//      [23..50]    mmr_roots
//      [51]        program_hash
//
//  ---> total: 52 public inputs
//
func verify_chain_states(prev_mem_values: felt*, next_mem_values: felt*){
    assert prev_mem_values[0] = next_mem_values[0];
    assert prev_mem_values[1] = next_mem_values[1];
    assert prev_mem_values[2] = next_mem_values[2];
    assert prev_mem_values[3] = next_mem_values[3];
    assert prev_mem_values[4] = next_mem_values[4];
    assert prev_mem_values[5] = next_mem_values[5];
    assert prev_mem_values[6] = next_mem_values[6];
    assert prev_mem_values[7] = next_mem_values[7];
    assert prev_mem_values[8] = next_mem_values[8];
    assert prev_mem_values[9] = next_mem_values[9];
    assert prev_mem_values[10] = next_mem_values[10];
    assert prev_mem_values[11] = next_mem_values[11];
    assert prev_mem_values[12] = next_mem_values[12];
    assert prev_mem_values[13] = next_mem_values[13];
    assert prev_mem_values[14] = next_mem_values[14];
    assert prev_mem_values[15] = next_mem_values[15];
    assert prev_mem_values[16] = next_mem_values[16];
    assert prev_mem_values[17] = next_mem_values[17];
    assert prev_mem_values[18] = next_mem_values[18];
    assert prev_mem_values[19] = next_mem_values[19];
    assert prev_mem_values[20] = next_mem_values[20];
    assert prev_mem_values[21] = next_mem_values[21];
    assert prev_mem_values[22] = next_mem_values[22];
    assert prev_mem_values[23] = next_mem_values[23];
    assert prev_mem_values[24] = next_mem_values[24];
    assert prev_mem_values[25] = next_mem_values[25];
    assert prev_mem_values[26] = next_mem_values[26];
    assert prev_mem_values[27] = next_mem_values[27];
    assert prev_mem_values[28] = next_mem_values[28];
    assert prev_mem_values[29] = next_mem_values[29];
    assert prev_mem_values[30] = next_mem_values[30];
    assert prev_mem_values[31] = next_mem_values[31];
    assert prev_mem_values[32] = next_mem_values[32];
    assert prev_mem_values[33] = next_mem_values[33];
    assert prev_mem_values[34] = next_mem_values[34];
    assert prev_mem_values[35] = next_mem_values[35];
    assert prev_mem_values[36] = next_mem_values[36];
    assert prev_mem_values[37] = next_mem_values[37];
    assert prev_mem_values[38] = next_mem_values[38];
    assert prev_mem_values[39] = next_mem_values[39];
    assert prev_mem_values[40] = next_mem_values[40];
    assert prev_mem_values[41] = next_mem_values[41];
    assert prev_mem_values[42] = next_mem_values[42];
    assert prev_mem_values[43] = next_mem_values[43];
    assert prev_mem_values[44] = next_mem_values[44];
    assert prev_mem_values[45] = next_mem_values[45];
    assert prev_mem_values[46] = next_mem_values[46];
    assert prev_mem_values[47] = next_mem_values[47];
    assert prev_mem_values[48] = next_mem_values[48];
    assert prev_mem_values[49] = next_mem_values[49];
    assert prev_mem_values[50] = next_mem_values[50];
    return ();
}