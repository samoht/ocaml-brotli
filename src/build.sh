#!/bin/sh

set -e

tar -xzf brotli-1.1.0.tar.gz
cd brotli-1.1.0

# $1 => c_compiler
# $2 => ocamlc_cflags
# $3 => supports_shared_libraries

CC="$1"
CFLAGS="$2 -O2"

# brotli's shared_dictionary.c includes the legacy <memory.h> alias for
# string.h, which minimal libcs (solo5 nolibc) do not ship; shim it.
mkdir -p shims
echo '#include <string.h>' > shims/memory.h
CFLAGS="$CFLAGS -Ishims"

# Minimal libcs may also omit the EXIT_* status macros the encoder's
# out-of-memory guard uses.
CFLAGS="$CFLAGS -DEXIT_FAILURE=1"

# Use the cross toolchain's archiver, derived from the C compiler's prefix,
# when it exists; the build machine's ar otherwise (see mirage/ocaml-gmp for
# the macOS host / ELF target mismatch this avoids).
cc_prog=${CC%% *}
tool_prefix=${cc_prog%-*}
AR=ar
RANLIB=ranlib
if [ "$tool_prefix" != "$cc_prog" ] && command -v "${tool_prefix}-ar" >/dev/null 2>&1; then
    AR="${tool_prefix}-ar"
    if command -v "${tool_prefix}-ranlib" >/dev/null 2>&1; then
        RANLIB="${tool_prefix}-ranlib"
    fi
fi

archive () {
    lib="$1"; shift
    objs=""
    for f in "$@"; do
        o="$(echo "$f" | tr / _ | sed 's/\.c$/.o/')"
        $CC $CFLAGS -Ic/include -c "$f" -o "$o"
        objs="$objs $o"
    done
    $AR rc "$lib" $objs
    $RANLIB "$lib"
}

archive libbrotlicommon.a c/common/*.c
archive libbrotlidec.a c/dec/*.c
archive libbrotlienc.a c/enc/*.c

cp libbrotlicommon.a libbrotlidec.a libbrotlienc.a ..
for h in decode encode port shared_dictionary types; do
    cp "c/include/brotli/$h.h" "../brotli_$h.h"
done
for lib in brotlicommon brotlidec brotlienc; do
    if [ "$3" = "true" ]; then
        $CC -shared "lib$lib.a" -o "../dll$lib.so" 2>/dev/null || : > "../dll$lib.so"
    else
        : > "../dll$lib.so"
    fi
done
