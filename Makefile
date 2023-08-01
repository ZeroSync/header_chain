
test:
	protostar test --cairo-path=./program/src

setup:
	cd prover; \
	git clone git@github.com:starkware-libs/cairo-lang.git; \ 
	cd cairo-lang; \
	git am ../0001-patch-verifier.patch; \
	cp -R src/starkware/cairo/* ~/cairo_venv/lib/python3.9/site-packages/starkware/cairo/ 


batch_proof:
# Compile batch program
	cairo-compile program/src/prove_batch.cairo --cairo_path program/src --output prover/build/prove_batch_compiled.json --proof_mode
# Prove batch program
	PYTHONPATH=$PYTHONPATH:. python prover/batch.py --batch_number=0 --batch_size=8


aggregate_proof:
# Compile aggregate program
	cairo-compile program/src/aggregate_proofs.cairo --cairo_path=./program/src --output=prover/build/aggregate_program_compiled.json --proof_mode
# Prove aggregate program
	PYTHONPATH=$PYTHONPATH:. python prover/aggregate.py --output_dir prover/build/aggregate_0-7 --prev_proof prover/build/batch_proofs/batch_0 --next_proof prover/build/batch_proofs/batch_1


increment_proof:
# Compile increment program
	cairo-compile program/src/increment_batch.cairo --cairo_path program/src --output prover/build/increment_batch_compiled.json --proof_mode
# Prove increment program
	PYTHONPATH=$PYTHONPATH:. python prover/increment.py --output_dir prover/build/increment_0-11 --prev_proof prover/build/aggregate_0-7 --batch_size=4
