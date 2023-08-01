# Header Chain Proof
A STARK proof of Bitcoin's header chain


## Run Tests
```sh
make test
```

## Generate Proofs

### Setup
This command installs all required dependencies 
```sh
make setup
```

### Batch Proof
This command proves a batch of headers

```sh
make BATCH_SIZE=63 BATCH_NUMBER=0 batch_proof
```

### Aggregate Proof
This command aggregates two batch proofs (or aggregate proofs) into a single, aggegated proof

```sh
make PREV_PROOF=batch_proofs/batch_0 NEXT_PROOF=batch_proofs/batch_1 START=0 END=125 aggregate_proof
```

### Increment Proof 
This command extends an aggregate or batch proof with a next batch

```sh
make BATCH_SIZE=63 START=0 END=62 PREV_PROOF=batch_proofs/batch_0 increment_proof
```
