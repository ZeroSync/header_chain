const rust = import('./pkg');

export function verify(program, public_input, proof){
    return rust.then( m => m.verify( new Uint8Array(program), new Uint8Array(public_input), new Uint8Array(proof) ) )
        .catch(console.error);
}