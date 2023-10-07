# Header Chain Verifier
This applies the Sandstorm verifier to the header chain proof and compiles it to WebAssembly.

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
python3 -m http.server
```
