# Header Chain Proof
A STARK proof of Bitcoin's header chain


## Run Tests
```
protostar test --cairo-path=./src
```


## Roundtrip
### Patch verifier
```sh
# Patch and include the verifier in your cairo-lang package
git clone git@github.com:starkware-libs/cairo-lang.git
cd cairo-lang
# Apply the path in the cairo-lang repo
git am ../header_chain/scripts/0001-patch-verifier.patch
# Switch out ~/cairo_venv/ with your cairo venv
cp -R src/starkware/cairo/* ~/cairo_venv/lib/python3.9/site-packages/starkware/cairo/
```

### Compile programs
```sh
# Aggregate program
cairo-compile src/aggregate_proofs.cairo --cairo_path=./src --output=tmp/aggregate_program_compiled.json --proof_mode

# Batch program
cairo-compile src/prove_batch.cairo --cairo_path src --output tmp/prove_batch_compiled.json --proof_mode

# Increment program
cairo-compile src/increment_batch.cairo --cairo_path src --output tmp/increment_batch_compiled.json --proof_mode
```

### Run scripts to generate proofs
```sh
# Aggregate program
PYTHONPATH=$PYTHONPATH:. python recursion_setup/aggregate.py --output_dir tmp/aggregate_0-7 --prev_proof tmp/batch_proofs/batch_0 --next_proof tmp/batch_proofs/batch_1

# Batch program
PYTHONPATH=$PYTHONPATH:. python recursion_setup/batch.py --batch_number=0 --batch_size=8

# Increment program
PYTHONPATH=$PYTHONPATH:. python recursion_setup/increment.py --output_dir tmp/increment_0-11 --prev_proof tmp/aggregate_0-7 --batch_size=4

```


