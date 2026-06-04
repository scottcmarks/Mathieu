// Thin wrappers around the Emscripten M12 engine (mathieu_engine.js, which
// exposes the global createMathieuEngine). Dart (mathieu_ffi_web.dart) binds to
// these via @JS. Handles the malloc/HEAP marshalling for int[] / string returns.
(function () {
  let M = null;

  async function mathieuWasmInit() {
    if (M) return;
    M = await createMathieuEngine();
  }

  function readInts(fill, n) {
    const p = M._malloc(n * 4);
    fill(p);
    const out = new Array(n);
    const base = p >> 2;
    for (let i = 0; i < n; i++) out[i] = M.HEAP32[base + i];
    M._free(p);
    return out;
  }
  const N = () => M._mathieu_num_balls();

  window.mathieuWasmInit = mathieuWasmInit;
  window.mathieuNumBalls = () => M._mathieu_num_balls();
  window.mathieuNumSwaps = () => M._mathieu_num_swaps();
  window.mathieuNew = () => M._mathieu_new();
  window.mathieuFree = (h) => M._mathieu_free(h);
  window.mathieuReset = (h) => M._mathieu_reset(h);
  window.mathieuLeft = (h) => M._mathieu_left(h, 1);
  window.mathieuRight = (h) => M._mathieu_right(h, 1);
  window.mathieuSwap = (h) => M._mathieu_swap(h);
  window.mathieuRandom = (h) => M._mathieu_random(h);
  window.mathieuUndo = (h, m) => M._mathieu_undo(h, m);
  window.mathieuRevert = (h) => M._mathieu_revert(h);
  window.mathieuMoves = (h) => M._mathieu_moves(h);
  window.mathieuSteps = (h) => M._mathieu_steps(h);
  window.mathieuHistoryLength = (h) => M._mathieu_history_length(h);
  window.mathieuIsSolved = (h) => M._mathieu_is_solved(h);
  window.mathieuArrangement = (h) => readInts((p) => M._mathieu_get_arrangement(h, p), N());
  window.mathieuSwapPermutation = () => readInts((p) => M._mathieu_get_swap_permutation(p), N());
  window.mathieuSwapPermutationAt = (i) => readInts((p) => M._mathieu_get_swap_permutation_at(i, p), N());
  window.mathieuSetSwapIndex = (i) => M._mathieu_set_swap_index(i);
  window.mathieuGetSwapIndex = () => M._mathieu_get_swap_index();
  window.mathieuSwapDifficulty = (i) => M._mathieu_swap_difficulty(i);
  window.mathieuMacroDefined = (h, c) => M._mathieu_macro_defined(h, c);
  window.mathieuAnyMacro = (h) => M._mathieu_any_macro_defined(h);
  window.mathieuSetMacro = (h, c) => M._mathieu_set_macro(h, c);
  window.mathieuEraseMacro = (h, c) => M._mathieu_erase_macro(h, c);
  window.mathieuEraseAllMacros = (h) => M._mathieu_erase_all_macros(h);
  window.mathieuRunMacro = (h, c, inv) => M._mathieu_run_macro(h, c, inv);
  window.mathieuHistoryIsSingleMacro = (h, c) => M._mathieu_history_is_single_macro(h, c);
  window.mathieuHistoryStr = (h) => {
    const cap = 256;
    const p = M._malloc(cap);
    M._mathieu_history_str(h, p, cap);
    const s = M.UTF8ToString(p);
    M._free(p);
    return s;
  };
})();
