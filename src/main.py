# PYTHONPATH=$PYTHONPATH:. python src/main.py
import subprocess
import os

SANDSTORM = "../sandstorm-mirror/target/release/sandstorm"
COMPILED_PROGRAM = "tmp/headers_chain_proof_compiled.json"
output_dir = "tmp"
chain_state_file = f"{output_dir}/headers_chain_state.json"
batch_size = 4
i = 0


cmd = f"cairo-compile src/prove_batch.cairo --cairo_path src --output tmp/headers_chain_proof_compiled.json --proof_mode"
subprocess.call(cmd, shell=True)

cmd = f"cairo-run \
            --program={COMPILED_PROGRAM} \
            --layout=recursive                  \
            --print_output                      \
            --program_input={chain_state_file}  \
            --trace_file={output_dir}/trace.bin \
            --memory_file={output_dir}/memory.bin \
            --air_private_input {output_dir}/air-private-input.json \
            --air_public_input {output_dir}/air-public-input.json \
            --proof_mode \
            --print_info"
subprocess.call(cmd, shell=True)

cmd = f"{SANDSTORM} --program {COMPILED_PROGRAM} \
        --air-public-input {output_dir}/air-public-input.json \
        prove --air-private-input {output_dir}/air-private-input.json \
        --output {output_dir}/headers_chain_proof-{str(batch_size - 1)}.bin"

subprocess.call(cmd, shell=True)