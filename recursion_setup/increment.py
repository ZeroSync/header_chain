import json
import argparse
import os
import subprocess
from utils.cairo_hash import fetch_compiled_program, compute_hash_chain

parser = argparse.ArgumentParser(description='Generate a increment proof')
parser.add_argument(
    '--output_dir',
    type=str,
    help="Output directory, e.g., increment_[START]-[END]")
parser.add_argument(
    '--prev_proof',
    type=str,
    help="Previous proof folder for this increment")
parser.add_argument(
    '--batch_size',
    type=int,
    default=1,
    help="Batch size to increment")
args = parser.parse_args()

output_dir = args.output_dir
os.system(f"mkdir -p {output_dir}")

PREV_PARSED_PROOF = f"{args.prev_proof}/parsed_proof.json"

SANDSTORM_PARSER = "../cairo-verifier-utils/target/debug/sandstorm_parser"
SANDSTORM = '\\time -f "%E %M" ../sandstorm-mirror/target/release/sandstorm'
INCREMENT_PROGRAM = "tmp/increment_batch_compiled.json"   # TODO CLI?

BATCH_SIZE = args.batch_size

with open(PREV_PARSED_PROOF) as file:
    prev_proof_json = json.load(file)

os.system(f"mkdir -p {output_dir}")
input_file = f"{output_dir}/hint_inputs.json"

# Create input file for this increment proof
with open(INCREMENT_PROGRAM, 'r') as file:
    program = fetch_compiled_program(file)
increment_program_hash = compute_hash_chain(program.data)
with open(input_file, 'w') as input_fp:
    input_dict = {
        "prev_proof": prev_proof_json,
        "increment_program_hash": increment_program_hash,
        "batch_size": BATCH_SIZE,
    }
    json.dump(input_dict, input_fp)

# Run Cairo runner
print("Starting Cairo runner.")
cmd = f"cairo-run \
            --program={INCREMENT_PROGRAM} \
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
cairo_output = os.popen(cmd).read()
print(cairo_output)

# Run Sandstorm prover
cmd = f'{SANDSTORM} --program {INCREMENT_PROGRAM} \
       --air-public-input {output_dir}/air-public-input.json \
       prove --air-private-input {output_dir}/air-private-input.json \
       --output {output_dir}/incremented_proof.bin'
subprocess.call(cmd, shell=True)

# Parse proof into cairo verifier readable format
cmd = f"{SANDSTORM_PARSER}  {output_dir}/incremented_proof.bin {output_dir}/air-public-input.json {INCREMENT_PROGRAM} {output_dir}/parsed_proof.json proof"
subprocess.call(cmd, shell=True)
