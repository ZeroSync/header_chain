import json
import argparse
import os
import subprocess
from utils.cairo_hash import fetch_compiled_program, compute_hash_chain

parser = argparse.ArgumentParser(description='Generate a aggregate proof')
parser.add_argument(
    '--output_dir',
    type=str,
    help="Output directory.")
parser.add_argument(
    '--prev_proof',
    type=str,
    help="Previous proof folder for this aggregation.")
parser.add_argument(
    '--next_proof',
    type=str,
    help="Next proof folder for this aggregation.")
parser.add_argument(
    '--start_height',
    type=str,
    help="Starting block_height of the previous proof that is aggregated. Only used for naming the output directory.."
)
parser.add_argument(
    '--end_height',
    type=str,
    help="End block_height of the next_proof that is aggregated. Only used for naming the output directory."
)
args = parser.parse_args()

PREV_PARSED_PROOF = f"{args.prev_proof}/parsed_proof.json"
NEXT_PARSED_PROOF = f"{args.next_proof}/parsed_proof.json"

SANDSTORM_PARSER = "../cairo-verifier-utils/target/debug/sandstorm_parser"
SANDSTORM = '\\time -f "%E %M" ../sandstorm-mirror/target/release/sandstorm'
PROOF_PARAMETERS = "--num-queries=26 --lde-blowup-factor=8 --proof-of-work-bits=20 --fri-folding-factor=8 --fri-max-remainder-coeffs=16"
AGGREGATE_PROGRAM = f"{args.output_dir}/aggregate_proofs_compiled.json"

with open(PREV_PARSED_PROOF) as file:
    prev_proof_json = json.load(file)
with open(NEXT_PARSED_PROOF) as file:
    next_proof_json = json.load(file)

output_dir = f"{args.output_dir}/aggregate_{args.start_height}-{args.end_height}"
os.system(f"mkdir -p {output_dir}")
input_file = f"{output_dir}/hint_inputs.json"

# Create input file for this aggregate proof
with open(AGGREGATE_PROGRAM, 'r') as file:
    program = fetch_compiled_program(file)
aggregate_program_hash = compute_hash_chain(program.data)
with open(input_file, 'w') as input_fp:
    input_dict = {
        "prev_proof": prev_proof_json,
        "next_proof": next_proof_json,
        "aggregate_program_hash": aggregate_program_hash,
    }
    json.dump(input_dict, input_fp)

# Run Cairo runner
print("Starting Cairo runner.")
cmd = f"cairo-run \
            --program={AGGREGATE_PROGRAM} \
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
cmd = f'{SANDSTORM} --program {AGGREGATE_PROGRAM} \
      --air-public-input {output_dir}/air-public-input.json \
      prove --air-private-input {output_dir}/air-private-input.json \
      --output {output_dir}/aggregated_proof.bin {PROOF_PARAMETERS}'
if rc := subprocess.call(cmd, shell=True) != 0:
    print(f"[ERROR] {cmd} failed with return code {rc}")
    exit(-1)
#
# Parse proof into cairo verifier readable format
cmd = f"{SANDSTORM_PARSER}  {output_dir}/aggregated_proof.bin {output_dir}/air-public-input.json {AGGREGATE_PROGRAM} {output_dir}/parsed_proof.json proof"
if rc := subprocess.call(cmd, shell=True) != 0:
    print(f"[ERROR] {cmd} failed with return code {rc}")
    exit(-1)
