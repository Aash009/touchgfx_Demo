#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/build/UnitTests"
source "$ROOT/scripts/resolve-ninja.sh"
if ! resolve_ninja; then
    echo "ERROR: Ninja is required for host unit tests (install it or use the STM32Cube bundle)." >&2
    exit 2
fi

# Fail early with a useful diagnostic if the host compiler lacks its linker
# runtime or (on Windows) the SDK libraries needed for native executables.
"$ROOT/scripts/check-host-compiler.sh"

# Host compiler for unit tests (NOT arm-none-eabi-gcc, and not MSVC).
if command -v gcc >/dev/null 2>&1 && command -v g++ >/dev/null 2>&1; then
    CC=gcc; CXX=g++
elif command -v clang >/dev/null 2>&1 && command -v clang++ >/dev/null 2>&1; then
    CC=clang; CXX=clang++
else
    echo "ERROR: no host gcc/clang on PATH (install MSYS2 MinGW-w64 or LLVM)." >&2
    exit 2
fi

CACHE_FILE="$BUILD_DIR/CMakeCache.txt"
if [ -f "$CACHE_FILE" ]; then
    cached_cc="$(sed -n 's/^CMAKE_C_COMPILER:[^=]*=//p' "$CACHE_FILE" | head -n 1)"
    selected_cc="$(command -v "$CC")"
    if command -v cygpath >/dev/null 2>&1; then
        cached_cc="$(cygpath -u "$cached_cc" 2>/dev/null || printf '%s' "$cached_cc")"
        selected_cc="$(cygpath -u "$selected_cc" 2>/dev/null || printf '%s' "$selected_cc")"
    fi
    if [ -n "$cached_cc" ] && [ "${cached_cc,,}" != "${selected_cc,,}" ]; then
        echo "Host compiler changed; clearing the generated unit-test CMake cache."
        rm -f "$CACHE_FILE"
        rm -rf "$BUILD_DIR/CMakeFiles"
    fi
fi

cmake -S "$ROOT/Tests" -B "$BUILD_DIR" -G Ninja \
      -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX"
cmake --build "$BUILD_DIR"
ctest --test-dir "$BUILD_DIR" --output-on-failure
