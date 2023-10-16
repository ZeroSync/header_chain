import pkg from 'zerosync_header_chain_verifier';
const { verify } = pkg;
import fs from 'fs';
function main() {
    // Sample serialized public input and proof. You'll replace these with real data.
    const publicInputBytes = new Uint8Array(fs.readFileSync('air-public-input.json'));
    const proofBytes = new Uint8Array(fs.readFileSync('proof.bin'));

    const result = verify(publicInputBytes, proofBytes);

    // Assuming the returned result has a property `isValid` to check the verification status
    if (result.isValid) {
        console.log("The header chain is valid!");
    } else {
        console.log("The header chain is invalid.");
    }
}
main();