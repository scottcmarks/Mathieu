#!/bin/bash
# Compile the M12 C++ engine to WebAssembly via Emscripten.
#   source ~/emsdk/emsdk_env.sh   (or have emcc on PATH)
#   ./build_wasm.sh
# Output: ../web/mathieu_engine.js + ../web/mathieu_engine.wasm
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
PI="$DIR/../../PlatformIndependent"
TOOLBOX="${HOME}/Toolbox/PlatformIndependent"
OUT="$DIR/../web"

if ! command -v emcc &>/dev/null; then
  if [ -f "${HOME}/emsdk/emsdk_env.sh" ]; then
    # shellcheck disable=SC1090
    source "${HOME}/emsdk/emsdk_env.sh" >/dev/null
  fi
fi
command -v emcc >/dev/null || { echo "emcc not found (source ~/emsdk/emsdk_env.sh)"; exit 1; }

INCS=(-I"$PI/Permutation" -I"$PI/M12/Permutation" -I"$DIR" -I"$TOOLBOX" -I"$TOOLBOX/Permutation")

EXPORTS='["_mathieu_new","_mathieu_free","_mathieu_num_balls","_mathieu_num_swaps","_mathieu_reset","_mathieu_left","_mathieu_right","_mathieu_swap","_mathieu_random","_mathieu_undo","_mathieu_revert","_mathieu_moves","_mathieu_steps","_mathieu_get_arrangement","_mathieu_history_length","_mathieu_history_is_empty","_mathieu_is_solved","_mathieu_history_str","_mathieu_set_swap_index","_mathieu_get_swap_index","_mathieu_swap_difficulty","_mathieu_get_swap_permutation","_mathieu_get_swap_permutation_at","_mathieu_macro_defined","_mathieu_any_macro_defined","_mathieu_set_macro","_mathieu_erase_macro","_mathieu_erase_all_macros","_mathieu_run_macro","_mathieu_history_is_single_macro","_mathieu_macro_permutation","_mathieu_macro_history_str","_mathieu_set_macro_from","_mathieu_get_start","_mathieu_set_position","_malloc","_free"]'

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
echo "  CC  rand_utils.c / emscripten_compat.c"
emcc -O2 -std=c17 "${INCS[@]}" -c "$TOOLBOX/rand_utils.c" -o "$TMP/rand_utils.o"
emcc -O2 -std=c17 "${INCS[@]}" -c "$DIR/emscripten_compat.c" -o "$TMP/compat.o"
echo "  CXX m12.cc / mathieu_ffi.cpp"
emcc -O2 -std=c++17 "${INCS[@]}" -c "$PI/M12/Permutation/m12.cc" -o "$TMP/m12.o"
emcc -O2 -std=c++17 "${INCS[@]}" -c "$DIR/mathieu_ffi.cpp" -o "$TMP/ffi.o"
echo "  LINK mathieu_engine.js"
emcc -O2 "$TMP"/*.o -o "$OUT/mathieu_engine.js" \
  -s WASM=1 -s MODULARIZE=1 -s EXPORT_NAME="createMathieuEngine" \
  -s EXPORTED_FUNCTIONS="$EXPORTS" \
  -s EXPORTED_RUNTIME_METHODS='["ccall","cwrap","getValue","setValue","UTF8ToString","HEAP32","HEAPU8"]' \
  -s ALLOW_MEMORY_GROWTH=1 -s NO_EXIT_RUNTIME=1 -s ENVIRONMENT=web

echo "Built: $OUT/mathieu_engine.js + .wasm"
ls -lh "$OUT"/mathieu_engine.*
