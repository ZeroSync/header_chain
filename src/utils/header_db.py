import os
filename = 'data/headers.bin'
if not os.path.isfile(filename):
    import urllib.request
    url = 'https://zerosync.org/chaindata/headers.bin'
    urllib.request.urlretrieve(url, filename)

headers = []
with open('data/headers.bin','rb') as file:
    while(header := file.read(80)):    
        headers.append(header)

print(f"Header database loaded. {len(headers)} items")

def get_block_header_raw(i):
    return headers[i].hex()