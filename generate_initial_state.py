import sys
import hashlib
import binascii
from starkware.cairo.lang.vm.crypto import pedersen_hash
import prover.utils.header_db as header_db

chain_length = int(sys.argv[1])
batch_size = int(sys.argv[2])

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
    return sum_felts(digest)

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
    for i in range(0, chain_length):
        leaf = hash_block(header_db.get_block_header_raw(i))
        mmr.add(leaf)
        if i % batch_size == batch_size - 1:
            print(f"{i} - state: {mmr.root_nodes}")
