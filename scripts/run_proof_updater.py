import argparse
import os
import time
import ftplib
# import smtplib
from program.src.utils.btc_api import BTCAPI

DEFAULT_BATCH_SIZE = 18
# How many blocks up to the chain tip have to exist
CHAINTIP_DELAY = 3

parser = argparse.ArgumentParser(
    description="Connect to a bitcoin instance to continuously generate proofs of the previous X block headers")
parser.add_argument("start_height")
parser.add_argument("--batch_size", default=DEFAULT_BATCH_SIZE, required=False)
parser.add_argument("ftp_username")
parser.add_argument("ftp_password")

args = parser.parse_args()


if __name__ == "__main__":
    # Set up bitcoin API
    btc_api = BTCAPI.make_BTCAPI()
    current_height = int(args.start_height)
    batch_size = int(args.batch_size)
    while True:
        remaining_blocks = btc_api.get_chain_length() - current_height
        if (remaining_blocks >= batch_size + CHAINTIP_DELAY):
            # Generate increment proof
            os.system(f"make BATCH_SIZE={batch_size} PREV_PROOF=increment_0-{current_height} END={current_height + batch_size} increment_proof")
            # Publish new proof via ftp
            current_height = current_height + batch_size
            try:
                session = ftplib.FTP_TLS('www382.your-server.de', args.ftp_username, args.ftp_password, )
                session.prot_p()
                proof_binary = open(f"prover/build/increment_0-{current_height}/increment_proof.bin", "rb")
                air_public_inputs = open(f"prover/build/increment_0-{current_height}/air-public-input.json", "rb")
                # Upload to a height_XYZ folder to store the proof
                session.mkd(f"height_{current_height}")
                session.cwd(f"height_{current_height}")
                session.storbinary("STOR aggregated_proof.bin", proof_binary)
                session.storbinary("STOR air-public-input.json", air_public_inputs)
                # Upload a copy of the proof to the "latest" folder
                session.cwd("../latest")
                session.storbinary("STOR aggregated_proof.bin", proof_binary)
                session.storbinary("STOR air-public-input.json", air_public_inputs)
                proof_binary.close()
                air_public_inputs.close()
                session.quit()
            except BaseException:
                # TODO: Send failure email/notification
                exit()
        else:
            # Wait 10 minutes for every block
            print(f"Waiting {batch_size + CHAINTIP_DELAY - remaining_blocks} blocks")
            time.sleep(600 * (batch_size + CHAINTIP_DELAY - remaining_blocks))
