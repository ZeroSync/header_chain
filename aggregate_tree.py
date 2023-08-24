import os

BLOCK_HEIGHT_OFFSET = 100000
BATCH_SIZE = 1300
BATCH_NUM = 64 # Has to be power of two
for i in range(BATCH_NUM):
    batch_cmd = f"make batch_proof BATCH_SIZE={BATCH_SIZE} BATCH_NUMBER={i}"
    print(batch_cmd)
    #os.system(batch_cmd)
    if i % 2 == 1:
        aggregate_cmd = f"make aggregate_proof PREV_PROOF=batch_proofs/batch_{i - 1} NEXT_PROOF=batch_proofs/batch_{i} START={(i - 1) * BATCH_SIZE + BLOCK_HEIGHT_OFFSET} END={(i + 1) * BATCH_SIZE - 1 + BLOCK_HEIGHT_OFFSET}"
        print(aggregate_cmd)
        # os.system(aggregate_cmd)
        j = 4
        while i % j == j - 1:
            start = (i + 1 - j) * BATCH_SIZE + BLOCK_HEIGHT_OFFSET
            mid = (i + 1 - j // 2) * BATCH_SIZE - 1 + BLOCK_HEIGHT_OFFSET
            end = (i + 1) * BATCH_SIZE - 1 + BLOCK_HEIGHT_OFFSET
            prev_proof = f"aggregate_{start}-{mid}"
            next_proof = f"aggregate_{mid + 1}-{end}"
            aggregate_cmd = f"make aggregate_proof PREV_PROOF={prev_proof} NEXT_PROOF={next_proof} START={start} END={end}"
            print(aggregate_cmd)
            # os.system(aggregate_cmd)
            j = j * 2
