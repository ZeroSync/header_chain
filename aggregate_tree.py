#import os
import sys

block_height_offset = int(sys.argv[1])

BATCH_SIZE = 1300
BATCH_NUM = 48
for i in range(BATCH_NUM):
    batch_cmd = f"make batch_proof BATCH_SIZE={BATCH_SIZE} BATCH_NUMBER={i}"
    print(batch_cmd)
    #os.system(batch_cmd)
    if i % 2 == 1:
        aggregate_cmd = f"make aggregate_proof PREV_PROOF=batch_proofs/batch_{i - 1} NEXT_PROOF=batch_proofs/batch_{i} START={(i - 1) * BATCH_SIZE + block_height_offset} END={(i + 1) * BATCH_SIZE - 1 + block_height_offset}"
        print(aggregate_cmd)
        # os.system(aggregate_cmd)
        j = 4
        while i % j == j - 1:
            start = (i + 1 - j) * BATCH_SIZE + block_height_offset
            mid = (i + 1 - j // 2) * BATCH_SIZE - 1 + block_height_offset
            end = (i + 1) * BATCH_SIZE - 1 + block_height_offset
            prev_proof = f"aggregate_{start}-{mid}"
            next_proof = f"aggregate_{mid + 1}-{end}"
            aggregate_cmd = f"make aggregate_proof PREV_PROOF={prev_proof} NEXT_PROOF={next_proof} START={start} END={end}"
            print(aggregate_cmd)
            # os.system(aggregate_cmd)
            j = j * 2
