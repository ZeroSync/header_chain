test:
	protostar test --cairo-path=./program/src target program

setup:
	cd prover; \
	git clone git@github.com:starkware-libs/cairo-lang.git; \ 
	cd cairo-lang; \
	git am ../0001-patch-verifier.patch; \
	cp -R src/starkware/cairo/* ~/cairo_venv/lib/python3.9/site-packages/starkware/cairo/ 

BUILD_DIR=prover/build
$(BUILD_DIR):
	mkdir -p $@

BATCH_SIZE=8
BATCH_NUMBER=0

batch_proof: $(BUILD_DIR)
	# Compile batch program
	cairo-compile program/src/prove_batch.cairo --cairo_path program/src --output $(BUILD_DIR)/prove_batch_compiled.json --proof_mode
	# Prove batch program
	PYTHONPATH=$$PYTHONPATH:. python prover/batch.py --batch_number=$(BATCH_NUMBER) --batch_size=$(BATCH_SIZE) --output_dir=$(BUILD_DIR)

AGGREGATE_RANGE=0-7
PREV_PROOF=batch_proofs/batch_0
NEXT_PROOF=batch_proofs/batch_1
aggregate_proof: $(BUILD_DIR)
	# Compile aggregate program
	cairo-compile program/src/aggregate_proofs.cairo --cairo_path=./program/src --output=$(BUILD_DIR)/aggregate_program_compiled.json --proof_mode
	# Prove aggregate program
	PYTHONPATH=$$PYTHONPATH:. python prover/aggregate.py --output_dir $(BUILD_DIR)/aggregate_$(AGGREGATE_RANGE) --prev_proof $(BUILD_DIR)/$(PREV_PROOF) --next_proof $(BUILD_DIR)/$(NEXT_PROOF)


increment_proof: $(BUILD_DIR)
	# Compile increment program
	cairo-compile program/src/increment_batch.cairo --cairo_path program/src --output $(BUILD_DIR)/increment_batch_compiled.json --proof_mode
	# Prove increment program
	PYTHONPATH=$$PYTHONPATH:. python prover/increment.py --output_dir $(BUILD_DIR)/increment_0-11 --prev_proof $(BUILD_DIR)/aggregate_0-7 --batch_size=4
