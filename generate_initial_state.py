import sys
import json
import hashlib
import binascii
from starkware.cairo.lang.vm.crypto import pedersen_hash
import prover.utils.header_db as header_db

chain_length = int(sys.argv[1])
batch_size = int(sys.argv[2])


def little_endian(string):
    splited = [str(string)[i: i + 2] for i in range(0, len(str(string)), 2)]
    splited.reverse()
    return "".join(splited)


def marshall_block_header(header):
    marshalled_header = {
        'version': int(little_endian(header[0:8]), 16),
        'previousblockhash': little_endian(header[8:72]),
        'merkle_root': little_endian(header[72:136]),
        'timestamp': int(little_endian(header[136:144]), 16),
        'bits': little_endian(header[144:152]),
        'nonce': int(little_endian(header[152:160]), 16),
    }
    return marshalled_header


def bits_to_target(bits):
    target = int(bits[2:8], 16) * 2 ** (8 * (int(bits[0:2], 16) - 3))
    return target


UINT32 = 2 ** 32
def sum_felts(block_hash):
    return int.from_bytes(block_hash[0:4], 'big') * UINT32 ** 0 + \
                 int.from_bytes(block_hash[4:8], 'big') * UINT32 ** 1 +  \
                 int.from_bytes(block_hash[8:12], 'big') * UINT32 ** 2 + \
                 int.from_bytes(block_hash[12:16], 'big') * UINT32 ** 3 + \
                 int.from_bytes(block_hash[16:20], 'big') * UINT32 ** 4 + \
                 int.from_bytes(block_hash[20:24], 'big') * UINT32 ** 5 + \
                 int.from_bytes(block_hash[24:28], 'big') * UINT32 ** 6

def hash_block(header):
    digest = hashlib.sha256(hashlib.sha256(binascii.unhexlify(header)).digest()).digest()
    return digest

# Compute the parent node of two nodes
def parent_node(root1, root2):
    root = pedersen_hash(root1, root2)
    return root


class MMR:
    def __init__(self) -> None:
        self.root_nodes = [None] * 27

    def add(self, leaf):
        n = leaf
        h = 0
        r = self.root_nodes[h]
        while r is not None:
            n = parent_node(r, n)
            self.root_nodes[h] = None
            h = h + 1
            r = self.root_nodes[h]

        self.root_nodes[h] = n

if __name__ == "__main__":
    mmr = MMR()
    timestamps = [0] * 11
    epoch_start_time = 0
    total_work = 0
    for i in range(0, chain_length):
        block_header = header_db.get_block_header_raw(i)
        header_json = marshall_block_header(block_header)
        block_hash = hash_block(block_header)
        leaf = sum_felts(block_hash)
        mmr.add(leaf)
        timestamps = [header_json["timestamp"]] + timestamps[:-1]
        total_work = total_work + (2 ** 256 // (bits_to_target(header_json["bits"]) + 1))
        if i % 2016 == 0:
            print("\rcurrent header: {i}/{chain_length}")
            epoch_start_time = header_json["timestamp"]
        if i % batch_size == batch_size - 1:
            chain_state = {
                    "block_height" : i,
                    "total_work": total_work,
                    "best_block_hash": binascii.hexlify(block_hash[::-1]).decode("ascii"),
                    "current_target": int(header_json["bits"], 16),
                    "epoch_start_time": epoch_start_time,
                    "prev_timestamps": timestamps,
                    "batch_size" : batch_size,
                    "mmr_roots" : ["0" if x is None else hex(x)[2:] for x in mmr.root_nodes]
            }
            with open(f"initial_states/state_{i}.json", "w") as f:
                json.dump(chain_state, f, indent = 4)
