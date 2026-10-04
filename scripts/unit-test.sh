#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Host compiler for unit tests (NOT arm-none-eabi-gcc, and not MSVC).
if command -v gcc >/dev/null 2>&1 && command -v g++ >/dev/null 2>&1; then
    CC=gcc; CXX=g++
elif command -v clang >/dev/null 2>&1 && command -v clang++ >/dev/null 2>&1; then
    CC=clang; CXX=clang++
else
    echo "ERROR: no host gcc/clang on PATH (install MSYS2 MinGW-w64 or LLVM)." >&2
    exit 2
fi

cmake -S "$ROOT/Tests" -B "$ROOT/build/UnitTests" -G Ninja \
      -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX"
cmake --build "$ROOT/build/UnitTests"
ctest --test-dir "$ROOT/build/UnitTests" --output-on-failure
