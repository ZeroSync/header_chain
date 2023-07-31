import json
import sys
from starkware.cairo.lang.vm.crypto import pedersen_hash
from starkware.cairo.lang.compiler.program import Program


def fetch_compiled_program(compiled_program_file):
    program = Program.Schema().load(json.load(compiled_program_file))
    return program


def compute_hash_chain(data):
    curr_hash = 0
    for i in range(len(data)):
        curr_hash = pedersen_hash(curr_hash, data[i])
    return pedersen_hash(curr_hash, len(data))


if __name__ == "__main__":
    with open(sys.argv[1], 'r') as file:
        program = fetch_compiled_program(file)
        program_hash = compute_hash_chain(program.data)
    print(hex(program_hash))
