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
make batch_proof
```

### Aggregate Proof
This command aggregates two batch proofs (or aggregate proofs) into a single, aggegated proof

```sh
make aggregate_proof
```

### Increment Proof 
This command extends an aggregate proof with a next header

```sh
make increment_proof
```