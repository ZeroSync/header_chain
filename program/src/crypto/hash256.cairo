
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_fp_and_pc

from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.memset import memset

from starkware.cairo.common.math import unsigned_div_rem

from utils.utils import UINT32_SIZE

from crypto.sha256_packed import (
    BLOCK_SIZE,
    SHIFTS,
    get_round_constants,
    compute_message_schedule,
    sha2_compress,
)

// The size of a block header is 80 bytes
const BLOCK_HEADER_SIZE = 80;
// The size of a block header encoded as an array of Uint32 is 20 felts
const BLOCK_HEADER_FELT_SIZE = BLOCK_HEADER_SIZE / UINT32_SIZE;

const SHA256_CHUNK_FELT_SIZE = 16;

const HASH256_INSTANCE_FELT_SIZE = 2 * SHA256_CHUNK_FELT_SIZE + Hash256.SIZE;

struct Hash256 {
    word_0: felt,
    word_1: felt,
    word_2: felt,
    word_3: felt,
    word_4: felt,
    word_5: felt,
    word_6: felt,
    word_7: felt,
}

func hash256_block_header{range_check_ptr, hash256_ptr: felt*}(block_header: felt*) -> felt* {
    alloc_locals;

    let chunk_0 = hash256_ptr;
    memcpy(hash256_ptr, block_header, BLOCK_HEADER_FELT_SIZE);
    let hash256_ptr = hash256_ptr + BLOCK_HEADER_FELT_SIZE;

    let chunk_1 = hash256_ptr + SHA256_CHUNK_FELT_SIZE - BLOCK_HEADER_FELT_SIZE;
    assert hash256_ptr[0] = 0x80000000;
    memset(hash256_ptr + 1, 0, 10);
    assert hash256_ptr[11] = 8 * BLOCK_HEADER_SIZE;
    let hash256_ptr = hash256_ptr + 2 * SHA256_CHUNK_FELT_SIZE - BLOCK_HEADER_FELT_SIZE;

    let hash256 = hash256_ptr;
    %{
        from starkware.cairo.common.cairo_sha256.sha256_utils import (
            IV, compute_message_schedule, sha2_compress_function)
        
        w = compute_message_schedule(memory.get_range(ids.chunk_0, ids.SHA256_CHUNK_FELT_SIZE))
        tmp = sha2_compress_function(IV, w)
        w = compute_message_schedule(memory.get_range(ids.chunk_1, ids.SHA256_CHUNK_FELT_SIZE))
        sha256 = sha2_compress_function(tmp, w)
        sha256 += [0x80000000] + 6 * [0] + [256]
        w = compute_message_schedule(sha256)
        hash256 = sha2_compress_function(IV, w)
        segments.write_arg(ids.hash256_ptr, hash256)
    %}
    let hash256_ptr = hash256_ptr + Hash256.SIZE;
    
    return hash256;
}

// NOTE: what about {message_schedule_ptr: felt*} ?

func _finalize_hash256_inner{range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(hash256_ptr: felt*, n: felt, initial_state: felt*, round_constants: felt*) {
    if (n == 0) {
        return ();
    }

    alloc_locals;

    local MAX_VALUE = 2 ** 32 - 1;

    let hash256_start = hash256_ptr;

    let (local message_start: felt*) = alloc();

    // Handle message.

    tempvar message = message_start;
    tempvar hash256_ptr = hash256_ptr;
    tempvar range_check_ptr = range_check_ptr;
    tempvar m = SHA256_CHUNK_FELT_SIZE;

    message_loop:
    tempvar x0 = hash256_ptr[0 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 0] = x0;
    assert [range_check_ptr + 1] = MAX_VALUE - x0;
    tempvar x1 = hash256_ptr[1 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 2] = x1;
    assert [range_check_ptr + 3] = MAX_VALUE - x1;
    tempvar x2 = hash256_ptr[2 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 4] = x2;
    assert [range_check_ptr + 5] = MAX_VALUE - x2;
    tempvar x3 = hash256_ptr[3 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 6] = x3;
    assert [range_check_ptr + 7] = MAX_VALUE - x3;
    tempvar x4 = hash256_ptr[4 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 8] = x4;
    assert [range_check_ptr + 9] = MAX_VALUE - x4;
    tempvar x5 = hash256_ptr[5 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 10] = x5;
    assert [range_check_ptr + 11] = MAX_VALUE - x5;
    tempvar x6 = hash256_ptr[6 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 12] = x6;
    assert [range_check_ptr + 13] = MAX_VALUE - x6;
    assert [message] = x0 + 2 ** (35 * 1) * x1 + 2 ** (35 * 2) * x2 + 2 ** (35 * 3) * x3 +
                            2 ** (35 * 4) * x4 + 2 ** (35 * 5) * x5 + 2 ** (35 * 6) * x6;

    tempvar message = message + 1;
    tempvar hash256_ptr = hash256_ptr + 1;
    tempvar range_check_ptr = range_check_ptr + 14;
    tempvar m = m - 1;
    jmp message_loop if m != 0;

    // Run hash256 on the 7 instances.
    
    local hash256_ptr: felt* = hash256_ptr;
    local range_check_ptr = range_check_ptr;
    compute_message_schedule(message_start);
    
    let chunk_0_state = sha2_compress(initial_state, message_start, round_constants);
    local bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;

    let (local message_start: felt*) = alloc();

    // Handle message.

    tempvar message = message_start;
    tempvar hash256_ptr = hash256_ptr;
    tempvar range_check_ptr = range_check_ptr;
    tempvar m = SHA256_CHUNK_FELT_SIZE;

    message_loop_2:
    tempvar x0 = hash256_ptr[0 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 0] = x0;
    assert [range_check_ptr + 1] = MAX_VALUE - x0;
    tempvar x1 = hash256_ptr[1 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 2] = x1;
    assert [range_check_ptr + 3] = MAX_VALUE - x1;
    tempvar x2 = hash256_ptr[2 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 4] = x2;
    assert [range_check_ptr + 5] = MAX_VALUE - x2;
    tempvar x3 = hash256_ptr[3 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 6] = x3;
    assert [range_check_ptr + 7] = MAX_VALUE - x3;
    tempvar x4 = hash256_ptr[4 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 8] = x4;
    assert [range_check_ptr + 9] = MAX_VALUE - x4;
    tempvar x5 = hash256_ptr[5 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 10] = x5;
    assert [range_check_ptr + 11] = MAX_VALUE - x5;
    tempvar x6 = hash256_ptr[6 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 12] = x6;
    assert [range_check_ptr + 13] = MAX_VALUE - x6;
    assert [message] = x0 + 2 ** (35 * 1) * x1 + 2 ** (35 * 2) * x2 + 2 ** (35 * 3) * x3 +
                            2 ** (35 * 4) * x4 + 2 ** (35 * 5) * x5 + 2 ** (35 * 6) * x6;

    tempvar message = message + 1;
    tempvar hash256_ptr = hash256_ptr + 1;
    tempvar range_check_ptr = range_check_ptr + 14;
    tempvar m = m - 1;
    jmp message_loop_2 if m != 0;

    // Run hash256 on the 7 instances.
   
    local hash256_ptr: felt* = hash256_ptr;
    local range_check_ptr = range_check_ptr;
    compute_message_schedule(message_start);
    
    let chunk_1_state = sha2_compress(chunk_0_state, message_start, round_constants);
    local bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;

    // Handle message.

    assert chunk_1_state[Hash256.SIZE] = SHIFTS * 0x80000000;
    memset(chunk_1_state + Hash256.SIZE + 1, 0, 6);
    assert chunk_1_state[Hash256.SIZE + 7] = SHIFTS * 32 * Hash256.SIZE;

    // Run hash256 on the 7 instances.
    
    local hash256_ptr: felt* = hash256_ptr;
    local range_check_ptr = range_check_ptr;
    compute_message_schedule(chunk_1_state);

    let outputs = sha2_compress(initial_state, chunk_1_state, round_constants);
    local bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
    
    // Handle outputs.
    tempvar outputs = outputs;
    tempvar hash256_ptr = hash256_ptr;
    tempvar range_check_ptr = range_check_ptr;
    tempvar m = Hash256.SIZE;

    output_loop:
    tempvar x0 = hash256_ptr[0 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr] = x0;
    assert [range_check_ptr + 1] = MAX_VALUE - x0;
    tempvar x1 = hash256_ptr[1 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 2] = x1;
    assert [range_check_ptr + 3] = MAX_VALUE - x1;
    tempvar x2 = hash256_ptr[2 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 4] = x2;
    assert [range_check_ptr + 5] = MAX_VALUE - x2;
    tempvar x3 = hash256_ptr[3 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 6] = x3;
    assert [range_check_ptr + 7] = MAX_VALUE - x3;
    tempvar x4 = hash256_ptr[4 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 8] = x4;
    assert [range_check_ptr + 9] = MAX_VALUE - x4;
    tempvar x5 = hash256_ptr[5 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 10] = x5;
    assert [range_check_ptr + 11] = MAX_VALUE - x5;
    tempvar x6 = hash256_ptr[6 * HASH256_INSTANCE_FELT_SIZE];
    assert [range_check_ptr + 12] = x6;
    assert [range_check_ptr + 13] = MAX_VALUE - x6;

    assert [outputs] = x0 + 2 ** (35 * 1) * x1 + 2 ** (35 * 2) * x2 + 2 ** (35 * 3) * x3 +
                            2 ** (35 * 4) * x4 + 2 ** (35 * 5) * x5 + 2 ** (35 * 6) * x6;

    tempvar outputs = outputs + 1;
    tempvar hash256_ptr = hash256_ptr + 1;
    tempvar range_check_ptr = range_check_ptr + 14;
    tempvar m = m - 1;
    jmp output_loop if m != 0;
    
    return _finalize_hash256_inner(hash256_start + HASH256_INSTANCE_FELT_SIZE * BLOCK_SIZE, n - 1, initial_state, round_constants);
}

func finalize_hash256_block_header{range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(hash256_ptr_start: felt*, hash256_ptr_end: felt*) {
    alloc_locals;

    let round_constants = get_round_constants();

    let initial_state = get_initial_state();    

    // We reuse the output state of the previous chunk as input to the next.
    tempvar num_instances = (hash256_ptr_end - hash256_ptr_start) / HASH256_INSTANCE_FELT_SIZE;
    if (num_instances == 0) {
        return ();
    }
    
    %{
        # Copy last hash256 instance as padding
        hash256 = memory.get_range(ids.hash256_ptr_end - ids.HASH256_INSTANCE_FELT_SIZE,
                                                         ids.HASH256_INSTANCE_FELT_SIZE)
        segments.write_arg(ids.hash256_ptr_end, (ids.BLOCK_SIZE - 1) * hash256)
    %}

    // Compute the amount of blocks (rounded up).
    let (num_instance_blocks, _) = unsigned_div_rem(num_instances + BLOCK_SIZE - 1, BLOCK_SIZE);

    _finalize_hash256_inner(hash256_ptr_start, num_instance_blocks, initial_state, round_constants);

    return ();
}

const INITIAL_STATE_H0 = SHIFTS * 0x6A09E667;
const INITIAL_STATE_H1 = SHIFTS * 0xBB67AE85;
const INITIAL_STATE_H2 = SHIFTS * 0x3C6EF372;
const INITIAL_STATE_H3 = SHIFTS * 0xA54FF53A;
const INITIAL_STATE_H4 = SHIFTS * 0x510E527F;
const INITIAL_STATE_H5 = SHIFTS * 0x9B05688C;
const INITIAL_STATE_H6 = SHIFTS * 0x1F83D9AB;
const INITIAL_STATE_H7 = SHIFTS * 0x5BE0CD19;

// Returns the initial input state to IV.
func get_initial_state{range_check_ptr}() -> felt* {
    alloc_locals;
    let (__fp__, _) = get_fp_and_pc();

    local initial_state = INITIAL_STATE_H0;
    local a = INITIAL_STATE_H1;
    local a = INITIAL_STATE_H2;
    local a = INITIAL_STATE_H3;
    local a = INITIAL_STATE_H4;
    local a = INITIAL_STATE_H5;
    local a = INITIAL_STATE_H6;
    local a = INITIAL_STATE_H7;

    return &initial_state;
}