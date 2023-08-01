# Header Chain Verifier

This applies the Sandstorm verifier to the header chain proof and compiles it to WebAssembly.

```
npm install

cargo install wasm-pack

npm run build

cp -r proofs pkg/proofs

cd pkg

python3 -m http.server

```