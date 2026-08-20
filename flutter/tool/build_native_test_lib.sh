#!/bin/bash
# Build the M12 engine as a plain shared library so `flutter test` can exercise
# the real dart:ffi bindings against the real C++ (test/engine_ffi_test.dart).
#
#   ./tool/build_native_test_lib.sh
#   MATHIEU_ENGINE_LIB="$(pwd)/build/native-test/libmathieu_engine.dylib" flutter test
#
# Without this the FFI test skips: the app targets link the engine into the app
# binary, and a standalone Dart VM has no such binary to look in.
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$DIR/build/native-test"
mkdir -p "$OUT"
cmake -S "$DIR/native" -B "$OUT" -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$OUT" --config Release

find "$OUT" -name 'libmathieu_engine.*' -o -name 'mathieu_engine.dll' | head -1
