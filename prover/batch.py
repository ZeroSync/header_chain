import subprocess
import os
import json
import argparse

from utils.cairo_parser import *


parser = argparse.ArgumentParser(description='Generate a chain proof')
parser.add_argument(
    '--output_dir',
    type=str,
    default='tmp',
    help="Output directory")
parser.add_argument(
    '--batch_number',
    type=int,
    help="Batch number in the tree recursion")
parser.add_argument(
    '--batch_size',
    type=int,
    default=1,
    help="Batch size to increment")
args = parser.parse_args()

SANDSTORM = '\\time -f "%E %M" ../sandstorm-mirror/target/release/sandstorm'
SANDSTORM_PARSER = "../cairo-verifier-utils/target/debug/sandstorm_parser"
PROOF_PARAMETERS = "--num-queries=24 --lde-blowup-factor=8 --proof-of-work-bits=30 --fri-folding-factor=8 --fri-max-remainder-coeffs=16"

BATCH_SIZE = args.batch_size
BATCH_NUMBER = args.batch_number
INITIAL_STATE_FILE = "prover/state_0.json"

COMPILED_PROGRAM = f"{args.output_dir}/prove_batch_compiled.json"
output_dir = f"{args.output_dir}/batch_proofs/batch_{BATCH_NUMBER}"
input_file = f"{output_dir}/hint_inputs.json"
output_file = f"{output_dir}/outputs.json"

# Create input file for this batch from previous output state
try:
    prev_output_file = open(
        f"{args.output_dir}/batch_proofs/batch_{BATCH_NUMBER-1}/outputs.json")
    prev_output = json.load(prev_output_file)['output']
except BaseException as e:
    if BATCH_NUMBER != 0:
        raise e
    prev_output_file = open(INITIAL_STATE_FILE)
    prev_output = json.load(prev_output_file)

with open(input_file, 'w') as input_fp:
    prev_output['batch_size'] = BATCH_SIZE
    json.dump(prev_output, input_fp)

# Run Cairo runner
print("Starting Cairo runner.")
cmd = f"cairo-run \
           --program={COMPILED_PROGRAM} \
           --layout=recursive                  \
           --print_output                      \
           --program_input={input_file}  \
           --trace_file={output_dir}/trace.bin \
           --memory_file={output_dir}/memory.bin \
           --air_private_input {output_dir}/air-private-input.json \
           --air_public_input {output_dir}/air-public-input.json \
           --proof_mode \
           --print_info \
           --print_output"
print(cmd)
cairo_output = os.popen(cmd).read()

print("Parsing Cairo output")
# Parse Cairo runner output to output json file
print(cairo_output)
cairo_outputs = parse_cairo_output(cairo_output)
r = FeltsReader(cairo_outputs)
chain_state = {
    'input': {
        'block_height': r.read(),
        'best_block_hash': felts_to_hash(r.read_n(8)),
        'total_work': r.read(),
        'current_target': r.read(),
        'prev_timestamps': r.read_n(11),
        'epoch_start_time': r.read(),
        'mmr_roots': felts_to_hex(r.read_n(27)),
    },
    'output': {
        'block_height': r.read(),
        'best_block_hash': felts_to_hash(r.read_n(8)),
        'total_work': r.read(),
        'current_target': r.read(),
        'prev_timestamps': r.read_n(11),
        'epoch_start_time': r.read(),
        'mmr_roots': felts_to_hex(r.read_n(27)),
    },
    # 'program_hash': hex(r.read()),
}
with open(output_file, 'w') as output_fp:
    json.dump(chain_state, output_fp)

# Run Sandstorm prover
cmd = f"{SANDSTORM} --program {COMPILED_PROGRAM} \
        --air-public-input {output_dir}/air-public-input.json \
        prove --air-private-input {output_dir}/air-private-input.json \
        --output {output_dir}/batch_proof.bin {PROOF_PARAMETERS}"
if rc := subprocess.call(cmd, shell=True) != 0:
    print(f"[ERROR] {cmd} failed with return code {rc}")
    exit(-1)

# Parse proof into cairo verifier readable format
cmd = f"{SANDSTORM_PARSER}  {output_dir}/batch_proof.bin {output_dir}/air-public-input.json {COMPILED_PROGRAM} {output_dir}/parsed_proof.json proof"
if rc := subprocess.call(cmd, shell=True) != 0:
    print(f"[ERROR] {cmd} failed with return code {rc}")
