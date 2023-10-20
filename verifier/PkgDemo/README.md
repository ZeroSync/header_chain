# zerosync__verifier
Zerosync verifier allows to verify ZeroSync‘s latest header chain STARK proofs in your node project. The proof validates the Bitcoin consensus for the header chain and provides the latest header chain state.


## Setup
```sh
# Copy compiled program over from prover/build
# You have to source your cairo_venv before that
cd ..; make prover/build/increment_batch_compiled.json; cd verifier ; \
cp ../prover/build/increment_batch_compiled.json .

npm install
cargo install wasm-pack
```

## Build 
```sh
npm run build
```

## Run Development Server 
```sh
cd build
python3 -m http.server 8001
```
