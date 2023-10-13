import pkg from 'zerosync_wasm';
const { verify } = pkg;
// Load inputs needed for the verify function
const publicInputBytes = new Uint8Array([]);
const proofBytes = new Uint8Array([]);

async function useVerifyFunction() {
    try {
        
        const result = await verify(publicInputBytes, proofBytes);
        
        if (result instanceof Error) {
            console.error("Verification error:", result.message);
        } else {
            console.log("Verification succeeded:", result);
        }
    } catch (error) {
        console.error("Error occurred:", error);
    }
}

useVerifyFunction();