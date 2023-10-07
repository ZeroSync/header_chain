use ark_serialize::CanonicalSerialize;
use binary::CompiledProgram;
use ministark_gpu::fields::p3618502788666131213697322783095070105623107215331596699973092056135872020481::ark::Fp;
use std::{env, fs::File, io, path::Path};

// TODO: generate program from `cairo-compile`
const PROGRAM_BYTES: &[u8] = include_bytes!("./increment_batch_compiled.json");

fn main() -> io::Result<()> {
    // Extract the compiled program data from the Cairo program JSON
    let program: CompiledProgram<Fp> = serde_json::from_reader(PROGRAM_BYTES).unwrap();
    let out_dir = env::var_os("OUT_DIR").unwrap();
    let path = Path::new(&out_dir).join("program.bin");
    program.serialize_compressed(File::create(path)?).unwrap();
    println!("cargo:rerun-if-changed=increment_batch_compiled.json");
    println!("cargo:rerun-if-changed=build.rs");
    Ok(())
}
