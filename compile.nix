with import <nixpkgs> {
  config = { allowUnsupportedSystem = true; };
  crossSystem = {
    config = "wasm32-unknown-wasi";
    libc = "wasilibc";
    cc = (import <nixpkgs> {}).llvmPackages_9.lldClang;
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
        nativeBuildInputs = [ wasilibc ];
        buildPhase = ''
          cp ${./src/tests.c} ./tests.c
          clang -O3 -flto \
            -emit-llvm --target=wasm32-wasi -c -S \
            -I${wasilibc}/include \
            -D_WASI_EMULATED_MMAN \
            -D__wasi__=1 \
            -D_ALL_SOURCE \
            ${wasilibc}/share/wasm32-wasi/include-all.c \
            tests.c

          ${pkgsOrig.llvm_9}/bin/llc -march=wasm32 -filetype=obj tests.s
          ${pkgsOrig.llvm_9}/bin/llc -march=wasm32 -filetype=obj include-all.s

          ${pkgsOrig.lld_9}/bin/wasm-ld \
            --lto-O3 \
            -entry=_start \
            --export-all \
            -L${wasilibc}/lib \
            -lc -lwasi-emulated-mman \
            -o tests.wasm \
            ${wasilibc}/lib/crt1.o \
            include-all.s.o \
            tests.s.o

            mkdir $out
            cp ./* $out
        '';
      };
    in
      mkShell {
        buildInputs = [ testP ];
        shellHook = ''
          echo ${wasilibc}/lib
          rm -rf ./lib
          mkdir -p lib
          cp ${testP}/tests.wasm lib
          chmod 0600 lib/tests.wasm
          exit 0
        '';
      }
  ) {}
