// Serialization and Validation of Bitcoin Block Headers
//
// See also:
// - Reference: https://developer.bitcoin.org/reference/block_chain.html#block-headers
// - Bitcoin Core: https://github.com/bitcoin/bitcoin/blob/7fcf53f7b4524572d1d0c9a5fdc388e87eb02416/src/primitives/block.h#L22

from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.math import assert_le, unsigned_div_rem, assert_le_felt, split_felt
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.bool import FALSE
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_neg,
    uint256_add,
    uint256_sub,
    uint256_mul,
    uint256_unsigned_div_rem,
    uint256_le,
)
from starkware.cairo.common.registers import get_fp_and_pc
from utils.utils import byteswap32, UINT32_SIZE, BYTE, assert_hashes_equal, felt_to_uint256
from crypto.hash256 import hash256_block_header, Hash256
from utils.pow2 import pow2
from block_header.median import compute_timestamps_median, TIMESTAMP_COUNT

// The minimum amount of work required for a block to be valid (represented as `bits`)
const MAX_BITS = 0x1d00FFFF;
// The minimum amount of work required for a block to be valid (represented as `target`)
const MAX_TARGET = 0x00000000FFFF0000000000000000000000000000000000000000000000000000;
// An epoch should be two weeks (represented as number of seconds)
// seconds/minute * minutes/hour * hours/day * 14 days
const EXPECTED_EPOCH_TIMESPAN = 60 * 60 * 24 * 14;
// Number of blocks per epoch
const BLOCKS_PER_EPOCH = 2016;


// Definition of a Bitcoin block header
//
// See also:
// - https://developer.bitcoin.org/reference/block_chain.html#block-headers
//
struct BlockHeader {
    // The block version number indicates which set of block validation rules to follow
    version: felt,

    // The hash of the previous block in the chain
    prev_block_hash: Hash256,

    // The Merkle root hash of all transactions in this block
    merkle_root_hash: Hash256,

    // The timestamp of this block header
    time: felt,

    // The target for the proof-of-work in compact encoding
    bits: felt,

    // The lucky nonce which solves the proof-of-work
    nonce: felt,
}

// A summary of the current state of a block chain
//
struct ChainState {
    // The number of blocks in the longest chain
    block_height: felt,

    // The total amount of work in the longest chain
    total_work: felt,

    // The block_hash of the current chain tip
    best_block_hash: felt*,

    // The required difficulty for targets in this epoch
    // In Bitcoin Core this is the result of GetNextWorkRequired
    current_target: felt,

    // The start time used to recalibrate the current_target
    // after an epoch of about 2 weeks (exactly 2016 blocks)
    epoch_start_time: felt,

    // The timestamps of the 11 most recent blocks
    prev_timestamps: felt*,
}

// Fetch a block header from our blockchain data provider
//
func fetch_block_header(block_height) -> BlockHeader* {
    let (block_header: BlockHeader*) = alloc();

    %{
        block_hex = get_block_header_raw(ids.block_height)
        from_hex(block_hex, ids.block_header.address_)
    %}
    return block_header;
}

// Calculate target from bits
//
// See also:
// - https://developer.bitcoin.org/reference/block_chain.html#target-nbits
//
func bits_to_target{range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(bits) -> felt {
    alloc_locals;
    // Ensure that the max target does not exceeded (0x1d00FFFF)
    with_attr error_message("Bits ({bits}) exceeded the max target ({MAX_BITS}).") {
        assert_le(bits, MAX_BITS);
    }

    // Decode the 4 bytes of `bits` into exponent and significand.
    // There's 1 byte for the exponent followed by 3 bytes for the significand

    // To do so, first we need a mask for the first 8 bits:
    const MASK_BITS_TO_SHIFT = 0xFF000000;
    // Then, using a bitwise AND to get only the first 8 bits.
    let (bits_to_shift) = bitwise_and(bits, MASK_BITS_TO_SHIFT);
    // And finally, do the shifts
    let exponent = bits_to_shift / 0x1000000;

    // Extract the last 3 bytes from `bits` to get the significand
    let (significand) = bitwise_and(bits, 0x00ffffff);

    // The target is the `significand` shifted `exponent` times to the left
    // when the exponent is greater than 3.
    // And it is `significand` shifted `exponent` times to the right when
    // it is less than 3.
    let is_greater_than_2 = (2 - exponent) * (1 - exponent) * exponent;
    if (is_greater_than_2 == 0) {
        let shift = pow2(8 * (3 - exponent));
        let (target, _rem) = unsigned_div_rem(significand, shift);
        return target;
    } else {
        let shift = pow2(8 * (exponent - 3));
        let target = significand * shift;
        return target;
    }
}

// Validate a block header, apply it to the previous state
// and return the next state
//
func validate_and_apply_block_header{
    range_check_ptr, bitwise_ptr: BitwiseBuiltin*, hash256_ptr: felt*, chain_state: ChainState
}(block_header: BlockHeader*) {
    alloc_locals;
    let (__fp__, _) = get_fp_and_pc();

    // Validate that a block header correctly extends the current chain
    //
    with_attr error_message("Invalid `prev_block_hash`. This block does not extend the current chain.") {
        assert_hashes_equal(chain_state.best_block_hash, &block_header.prev_block_hash);
    }

    // Swap endianness
    let n_bits = byteswap32(block_header.bits);
    let time   = byteswap32(block_header.time);
    
    // Validate and apply state transition
    let next_block_height     = chain_state.block_height + 1;
    let next_block_hash       = hash256_block_header(block_header);
    let next_total_work       = validate_proof_of_work(chain_state.total_work, chain_state.current_target, n_bits, next_block_hash);
    let (next_current_target,
         next_epoch_start_time) = adjust_difficulty(time, chain_state.current_target, next_block_height, chain_state.epoch_start_time);
    let next_timestamps       = validate_and_compute_timestamps(time, chain_state.current_target, chain_state.prev_timestamps);

    // Apply a block header to a previous chain state to obtain the next chain state
    //
    let chain_state = ChainState(
        block_height     = next_block_height,
        total_work       = next_total_work,
        best_block_hash  = next_block_hash,
        current_target   = next_current_target,
        epoch_start_time = next_epoch_start_time,
        prev_timestamps  = next_timestamps
    );
    return ();
}

func validate_proof_of_work{range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    prev_total_work, prev_n_bits, next_n_bits, next_block_hash: felt*
) ->  felt {
    alloc_locals;

    // Validate that the proof-of-work target is sufficiently difficult
    //
    // See also:
    // - https://github.com/bitcoin/bitcoin/blob/7fcf53f7b4524572d1d0c9a5fdc388e87eb02416/src/pow.cpp#L13
    // - https://github.com/bitcoin/bitcoin/blob/3a7e0a210c86e3c1750c7e04e3d1d689cf92ddaa/src/rpc/blockchain.cpp#L76
    //
    with_attr error_message("Target is {next_n_bits}. Expected {prev_n_bits}") {
        assert prev_n_bits = next_n_bits;
    }

    // Validate that a block header's proof-of-work matches its target.
    // Expects that the 4 most significant bytes of `block_hash` are zero.
    //

    // Swap the endianess in the uint32 chunks of the hash
    let hash_word_0_endian = byteswap32([next_block_hash + 0]);
    let hash_word_1_endian = byteswap32([next_block_hash + 1]);
    let hash_word_2_endian = byteswap32([next_block_hash + 2]);
    let hash_word_3_endian = byteswap32([next_block_hash + 3]);
    let hash_word_4_endian = byteswap32([next_block_hash + 4]);
    let hash_word_5_endian = byteswap32([next_block_hash + 5]);
    let hash_word_6_endian = byteswap32([next_block_hash + 6]);
    let hash_word_7 = [next_block_hash + 7];

    // Validate that the hash's most significant uint32 chunk is zero
    // This guarantees that the hash fits into a felt.
    with_attr error_message("Expected the block hash's most significant uint32 chunk ({hash_word_7}) to be zero") {
        assert 0 = hash_word_7;
    }

    // Sum up the other 7 uint32 chunks of the hash into 1 felt
    const BASE = 2 ** 32;
    let hash_as_felt = hash_word_0_endian * BASE ** 0 +
                       hash_word_1_endian * BASE ** 1 +
                       hash_word_2_endian * BASE ** 2 +
                       hash_word_3_endian * BASE ** 3 +
                       hash_word_4_endian * BASE ** 4 +
                       hash_word_5_endian * BASE ** 5 +
                       hash_word_6_endian * BASE ** 6;

    let target = bits_to_target(next_n_bits);

    // Validate that the hash is smaller than the target
    with_attr error_message(
            "Insufficient proof of work. Expected block hash ({hash_as_felt}) to be less than or equal to target ({target}).") {
        assert_le_felt(hash_as_felt, target);
    }

    // Compute the total work invested into the chain
    //
    let work_in_block = compute_work_from_target(target);
    return prev_total_work + work_in_block;
}

func validate_and_compute_timestamps{range_check_ptr}(time, prev_n_bits, prev_timestamps: felt*) -> felt* {
    alloc_locals;
    
    // Validate that the timestamp of a block header is strictly greater than the median time
    // of the 11 most recent blocks.
    //
    // See also:
    // - https://developer.bitcoin.org/reference/block_chain.html#block-headers
    // - https://github.com/bitcoin/bitcoin/blob/36c83b40bd68a993ab6459cb0d5d2c8ce4541147/src/chain.h#L290
    //
    let median_time = compute_timestamps_median(prev_timestamps);

    // Compare this block's timestamp to the median time
    with_attr error_message("Median time ({median_time}) is greater than block's timestamp ({time}).") {
        assert_le(median_time, time);
    }

    // Compute the 11 most recent timestamps for the next state
    //

    // Copy the timestamp of the most recent block
    let (timestamps) = alloc();
    assert timestamps[0] = time;

    // Copy the 10 most recent timestamps from the previous state
    memcpy(timestamps + 1, prev_timestamps, TIMESTAMP_COUNT - 1);
    return timestamps;
}

// Convert a target into units of work.
// Work is the expected number of hashes required to hit a target.
//
// See also:
// - https://bitcoin.stackexchange.com/questions/936/how-does-a-client-decide-which-is-the-longest-block-chain-if-there-is-a-fork/939#939
// - https://github.com/bitcoin/bitcoin/blob/v0.16.2/src/chain.cpp#L121
// - https://github.com/bitcoin/bitcoin/blob/v0.16.2/src/validation.cpp#L3713
//
func compute_work_from_target{range_check_ptr}(target) -> felt {
    let (hi, lo) = split_felt(target);
    let target256 = Uint256(lo, hi);
    let (neg_target256) = uint256_neg(target256);
    let (not_target256) = uint256_sub(neg_target256, Uint256(1, 0));
    let (div, _) = uint256_unsigned_div_rem(not_target256, target256);
    let (result, _) = uint256_add(div, Uint256(1, 0));
    return result.low + result.high * 2 ** 128;
}

// Adjust the current_target after about 2 weeks of blocks
// See also:
// - https://en.bitcoin.it/wiki/Difficulty
// - https://en.bitcoin.it/wiki/Target
// - https://github.com/bitcoin/bitcoin/blob/7fcf53f7b4524572d1d0c9a5fdc388e87eb02416/src/pow.cpp#L49
//
func adjust_difficulty{range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    time, prev_n_bits, block_height, prev_epoch_start_time
) -> (current_target: felt, epoch_start_time: felt) {
    alloc_locals;

    let (_, position_in_epoch) = unsigned_div_rem(block_height, BLOCKS_PER_EPOCH);
    if (position_in_epoch == BLOCKS_PER_EPOCH - 1) {
        // This is the last block of the current epoch, so we adjust the current_target now.

        //
        // This code is ported from Bitcoin Core
        // https://github.com/bitcoin/bitcoin/blob/7fcf53f7b4524572d1d0c9a5fdc388e87eb02416/src/pow.cpp#L49
        //

        let fe_actual_timespan = time - prev_epoch_start_time;

        // Limit adjustment step
        let is_too_large = is_le_felt(EXPECTED_EPOCH_TIMESPAN * 4, fe_actual_timespan);
        let is_too_small = is_le_felt(fe_actual_timespan, EXPECTED_EPOCH_TIMESPAN / 4);

        if (is_too_large == 1) {
            tempvar fe_actual_timespan = EXPECTED_EPOCH_TIMESPAN * 4;
        } else {
            if (is_too_small == 1) {
                tempvar fe_actual_timespan = EXPECTED_EPOCH_TIMESPAN / 4;
            } else {
                tempvar fe_actual_timespan = fe_actual_timespan;
            }
        }
        let actual_timespan = felt_to_uint256(fe_actual_timespan);
        // Retarget
        let bn_pow_limit = felt_to_uint256(MAX_TARGET);

        let fe_target = bits_to_target(prev_n_bits);
        let bn_new = felt_to_uint256(fe_target);
        let (bn_new, _) = uint256_mul(bn_new, actual_timespan);
        let UINT256_MAX_EPOCH_TIME = felt_to_uint256(EXPECTED_EPOCH_TIMESPAN);
        let (bn_new, _) = uint256_unsigned_div_rem(bn_new, UINT256_MAX_EPOCH_TIME);
        let next_bits = bn_new.low + bn_new.high * 2 ** 128;

        let (below_limit) = uint256_le(bn_new, bn_pow_limit);
        if (below_limit == 1) {
            let next_n_bits = target_to_bits(bn_new.low + bn_new.high * 2 ** 128);
            // Return next target and reset the epoch start time
            return (next_n_bits, time);
        } else {
            // Return MAX_BITS and reset the epoch start time
            return (MAX_BITS, time);
        }
    } else {
        return (prev_n_bits, prev_epoch_start_time);
    }
}

// Calculate bits from target
//
func target_to_bits{range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(target) -> felt {
    alloc_locals;
    local bits;

    %{
        def target_to_bits(target):
            if target == 0:
                return 0
            target = min(target, ids.MAX_TARGET)
            size = (target.bit_length() + 7) // 8
            mask64 = 0xffffffffffffffff
            if size <= 3:
                compact = (target & mask64) << (8 * (3 - size))
            else:
                compact = (target >> (8 * (size - 3))) & mask64

            if compact & 0x00800000:
                compact >>= 8
                size += 1
            assert compact == (compact & 0x007fffff)
            assert size < 256
            return compact | size << 24

        ids.bits = target_to_bits(ids.target)
    %}

    /// Compute the `exponent` which is the most significant byte of `bits`.

    // To do so, first we need a mask with the first 8 bits:
    const MASK_BITS_TO_SHIFT = 0xFF000000;
    // Then, using a bitwise and to get only the first 8 bits.
    let (bits_to_shift) = bitwise_and(bits, MASK_BITS_TO_SHIFT);
    // And finally, do the shifts
    let exponent = bits_to_shift / 0x1000000;

    let expected_target = bits_to_target(bits);

    let is_greater_than_2 = (2 - exponent) * (1 - exponent) * exponent;
    if (is_greater_than_2 == FALSE) {
        with_attr error_message("Hint provided an invalid value for `bits`") {
            assert expected_target = target;
        }
        return bits;
    } else {
        // if exponent >= 3 we check that
        // ((target & (threshold * 0xffffff)) - expected_target) == 0
        let threshold = pow2(8 * (exponent - 3));
        let mask = threshold * 0xffffff;
        let (masked_target) = bitwise_and(target, mask);
        with_attr error_message("Hint provided an invalid value for `bits`") {
            assert masked_target = expected_target;
        }
        return bits;
    }
}
