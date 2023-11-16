# ZeroSync Verifier (Rust and WASM)
The ZeroSync verifier allows to verify ZeroSync‘s latest header chain STARK proofs in your node or rust project. The proof validates the Bitcoin consensus for the header chain and provides the latest header chain state.
To Instantly verify Bitcoin's header chain in your browser, check out our [demo here](https://https://zerosync.org/demo/) 

## Installation
#### NPM
```sh
npm i zerosync_header_chain_verifier
```
OR 
#### YARN
```sh
yarn add zerosync_header_chain_verifier
```

## Quick Start
Here's a simple example to get you started:


```sh
import pkg from "zerosync_verifier";
const { verify } = pkg;
import fetch from "node-fetch";

async function main() {

    // The public input and proof are extracted from the latest data
  const publicInputUrl = "https://zerosync.org/demo/proofs/latest/air-public-input.json";
  const proofUrl =  "https://zerosync.org/demo/proofs/latest/aggregated_proof.bin";

  const publicInputResponse = await fetch(publicInputUrl);
  const publicInputBytes = new Uint8Array(
    await publicInputResponse.arrayBuffer()
  );

  const proofResponse = await fetch(proofUrl);
  const proofBytes = new Uint8Array(await proofResponse.arrayBuffer());

  //  Verifies the proof  and returns the result
  const result = verify(publicInputBytes, proofBytes);
  console.log(result);

}
main();
```

## Dependencies
- Ministark: GPU accelerated STARK prover and verifier
- Sandstorm: Cairo prover powered by miniSTARK
