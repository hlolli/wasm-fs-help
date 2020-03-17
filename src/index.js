import { WASI } from "@wasmer/wasi";
import { WasmFs } from "@wasmer/wasmfs";
import browserBindings from "@wasmer/wasi/lib/bindings/browser";
import { lowerI64Imports } from "@wasmer/wasm-transformer";
import * as path from "path";

const decoder = new TextDecoder("utf8");
export const uint2Str = uint => decoder.decode(uint);

export const cleanStdout = stdout => {
  const pattern = [
    "[\\u001B\\u009B][[\\]()#;?]*(?:(?:(?:[a-zA-Z\\d]*(?:;[-a-zA-Z\\d\\/#&.:=?%@~_]*)*)?\\u0007)",
    "(?:(?:\\d{1,4}(?:;\\d{0,4})*)?[\\dA-PR-TZcf-ntqry=><~]))"
  ].join("|");
  const regexPattern = new RegExp(pattern, "g");
  return stdout.replace(regexPattern, "");
};

const defaultMessageCallback = data => {
  const cleanString = cleanStdout(uint2Str(data));
  cleanString.split("\n").forEach(line => {
    console.log(line);
  });
};

export const wasmFs = new WasmFs();
const env = {};

const bindings = {
  ...browserBindings,
  fs: wasmFs.fs,
  path
};

const preopens = {
  "/": "/"
};

const wasi = new WASI({
  preopens,
  env,
  bindings
});

const load = async () => {
  const { default: response } = await import("../lib/tests.wasm");
  await wasmFs.volume.mkdirSync("/sandbox");
  const wasmBytes = new Uint8Array(response);
  const transformedBinary = await lowerI64Imports(wasmBytes);
  const module = await WebAssembly.compile(transformedBinary);
  const options = wasi.getImports(module);
  options["env"] = env;
  const instance = await WebAssembly.instantiate(module, options);
  wasi.start(instance);
  const stdout = wasmFs.fs.ReadStream("/dev/stdout", "utf8");
  const stderr = wasmFs.fs.ReadStream("/dev/stderr", "utf8");
  stdout.on("data", defaultMessageCallback);
  stderr.on("data", defaultMessageCallback);
  return instance;
};

const main = async () => {
  const wasm = await load();
  wasm.exports.add();
  console.log(
    "File cotents after the wasm module wrote into the sandbox: ",
    wasmFs.fs.readdirSync("/sandbox/")
  );
};

main();
