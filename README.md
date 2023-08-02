# Header Chain Proof
A STARK proof of Bitcoin's header chain


## Run Tests
```sh
make test
```

## Generate Proofs

### Setup
This command installs all required dependencies if you have your cairo\_venv at ~/cairo\_venv.
```sh
make setup
```

### Batch Proof
This command proves a batch of headers.

```sh
make batch_proof BATCH_SIZE=63 BATCH_NUMBER=0 
```

### Aggregate Proof
This command aggregates two batch proofs (or aggregate proofs) into a single, aggegated proof.

```sh
make aggregate_proof PREV_PROOF=batch_proofs/batch_0 NEXT_PROOF=batch_proofs/batch_1 START=0 END=125 
```

### Increment Proof 
This command extends an aggregate or batch proof with a next batch.

```sh
make increment_proof BATCH_SIZE=63 START=0 END=62 PREV_PROOF=batch_proofs/batch_0 
```

## Develop
### Update program hashes
```sh
make batch_program_hash
```
