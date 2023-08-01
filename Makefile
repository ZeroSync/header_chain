.DELETE_ON_ERROR: $(BUILD_DIR)/%_compiled.json

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

CAIRO_DEPENDENCIES=$(shell find program/src -type f -iname "*.cairo" -not -iname "*aggregate_proofs.cairo" -not -iname "*increment_batch.cairo" -not -iname "*prove_batch.cairo")
# Compilation rule for all three cairo programs
$(BUILD_DIR)/%_compiled.json: program/src/%.cairo $(CAIRO_DEPENDENCIES) $(BUILD_DIR)
	cairo-compile $< --cairo_path program/src --output $@ --proof_mode


BATCH_SIZE=8
BATCH_NUMBER=0
batch_proof: $(BUILD_DIR)/prove_batch_compiled.json
	# Prove batch program
	PYTHONPATH=$$PYTHONPATH:. python prover/batch.py --batch_number=$(BATCH_NUMBER) --batch_size=$(BATCH_SIZE) --output_dir=$(BUILD_DIR)

START=0
END=$(START) + $(BATCH_SIZE) - 1
PREV_PROOF=batch_proofs/batch_0
NEXT_PROOF=batch_proofs/batch_1
aggregate_proof: $(BUILD_DIR)/aggregate_proofs_compiled.json
	# Prove aggregate program
	PYTHONPATH=$$PYTHONPATH:. python prover/aggregate.py --output_dir=$(BUILD_DIR) --prev_proof=$(BUILD_DIR)/$(PREV_PROOF) --next_proof=$(BUILD_DIR)/$(NEXT_PROOF) --start_height=$(START) --end_height=$(END)

PREV_PROOF=increment_0-$(BATCH_SIZE)
increment_proof: $(BUILD_DIR)/increment_batch_compiled.json
	# Prove increment program
	PYTHONPATH=$$PYTHONPATH:. python prover/increment.py --output_dir=$(BUILD_DIR) --prev_proof=$(BUILD_DIR)/increment_0 --batch_size=$(BATCH_SIZE) --start_height=$(START) --end-height=$(END)
