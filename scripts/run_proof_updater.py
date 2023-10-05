import argparse
import os
import time
from program.src.utils.btc_api import BTCAPI

DEFAULT_BATCH_SIZE = 660
# How many blocks up to the chain tip have to exist
CHAINTIP_DELAY = 6

parser = argparse.ArgumentParser(
    description="Connect to a bitcoin instance to continuously generate proofs of the previous X block headers")
parser.add_argument("start_height")
parser.add_argument("batch_size", default=DEFAULT_BATCH_SIZE)

args = parser.parse_args()


if __name__ == "__main__":
    # Set up bitcoin API
    btc_api = BTCAPI.make_BTCAPI()
    current_height = int(args.start_height)
    batch_size = int(args.batch_size)
    while True:
        remaining_blocks = btc_api.get_chain_length() - current_height
        if (remaining_blocks >= batch_size + CHAINTIP_DELAY):
            # TODO: Generate increment proof
            os.system(f"make BATCH_SIZE={batch_size} PREV_PROOF=increment_0-{current_height} END={current_height + batch_size} increment_proof")
            # TODO: Check proof for failure and send email
            # TODO: Publish new proof via ftp
            print(f"Proving {current_height + batch_size}")
            current_height = current_height + batch_size
        else:
            # Wait 10 minutes for every block
            print(f"Waiting {batch_size + CHAINTIP_DELAY - remaining_blocks} blocks")
            time.sleep(600 * (batch_size + CHAINTIP_DELAY - remaining_blocks))
