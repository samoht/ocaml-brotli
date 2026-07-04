# ocaml-brotli

Dune packaging of [Brotli](https://github.com/google/brotli), suitable for
cross-compilation, following the approach of
[mirage/ocaml-gmp](https://github.com/mirage/ocaml-gmp).

The upstream `brotli-1.1.0` release tarball is vendored verbatim (MIT, The
Brotli Authors) and compiled by a dune rule with the selected toolchain's C
compiler. Installing the package into a findlib cross toolchain (for example
the `solo5` toolchain, via `opam-x`) provides:

- `libbrotlicommon.a`, `libbrotlidec.a`, `libbrotlienc.a` and the
  `brotli/*.h` headers under `lib/brotli`;
- relocatable `pkgconfig/libbrotli{common,dec,enc}.pc`, so consumers that
  discover Brotli through `pkg-config` (for example `bytesrw-brotli`) find
  the target-ABI libraries.
