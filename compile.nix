with import <nixpkgs> {
  config = { allowUnsupportedSystem = true; };
  crossSystem = {
    config = "wasm32-unknown-wasi";
    libc = "wasilibc";
    useLLVM = true;
  };
};
pkgs.callPackage
  (
    { mkShell }:
    let
      pkgsOrig = import <nixpkgs> {};
      wasilibc = pkgs.callPackage ./wasilibc.nix {
        stdenv = pkgs.stdenv;
        fetchFromGitHub = pkgs.fetchFromGitHub;
        lib = pkgs.lib;
      };
      testP = pkgs.stdenv.mkDerivation {
        name = "short-test-deleteme";
        phases = [ "buildPhase" ];
        nosource = true;
        buildPhase = ''
          cp ${./src/tests.c} ./tests.c
          clang -O3 -flto \
            -emit-llvm --target=wasm32-wasi -c -S \
            -I${wasilibc}/include \
            -D__wasi__=1 \
            tests.c

          ${pkgsOrig.llvm_9}/bin/llc -march=wasm32 -filetype=obj tests.s

          ${pkgsOrig.lld_9}/bin/wasm-ld \
            --lto-O3 \
            --export-all \
            --no-entry \
            -L${wasilibc}/lib \
            -lc -lm -ldl \
            -o tests.wasm \
            tests.s.o

            mkdir $out
            cp tests.wasm $out
        '';
      };
    in
      mkShell {
        buildInputs = [ testP ];
        shellHook = ''
          rm -f ./lib
          mkdir -p lib
          cp ${testP}/tests.wasm lib
          chmod 0600 lib/tests.wasm
          exit 0
        '';
      }
  ) {}
