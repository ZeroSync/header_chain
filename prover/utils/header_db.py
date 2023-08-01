import os
FILENAME = "prover/build/headers.bin"
HEADER_SIZE = 80
if not os.path.isfile(FILENAME):
    print("Downloading header database...")
    import urllib.request
    url = "https://zerosync.org/chaindata/headers.bin"
    urllib.request.urlretrieve(url, FILENAME)

headers = []
with open(FILENAME,"rb") as file:
    while(header := file.read(HEADER_SIZE)):
        headers.append(header)

print(f"Loaded header database. {len(headers)} items")

def get_block_header_raw(i):
    return headers[i].hex()