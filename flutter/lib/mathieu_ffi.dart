// Dart FFI bindings for the Mathieu "M12" C++ engine.
//
// On iOS/macOS the engine is compiled into the app binary, so we load it with
// DynamicLibrary.process(). On Android/Linux/Windows it ships as a shared lib.
// (Web uses a separate js_interop path — added later.)

import 'dart:ffi';
import 'package:ffi/ffi.dart';

// ---- native function typedefs ----
typedef _NewC = Pointer<Void> Function();
typedef _NewDart = Pointer<Void> Function();
typedef _FreeC = Void Function(Pointer<Void>);
typedef _Free = void Function(Pointer<Void>);
typedef _IntVoidC = Int32 Function();
typedef _IntVoid = int Function();
typedef _VoidPtrC = Void Function(Pointer<Void>);
typedef _VoidPtr = void Function(Pointer<Void>);
typedef _VoidPtrIntC = Void Function(Pointer<Void>, Int32);
typedef _VoidPtrInt = void Function(Pointer<Void>, int);
typedef _IntPtrC = Int32 Function(Pointer<Void>);
typedef _IntPtr = int Function(Pointer<Void>);
typedef _VoidPtrArrC = Void Function(Pointer<Void>, Pointer<Int32>);
typedef _VoidPtrArr = void Function(Pointer<Void>, Pointer<Int32>);
typedef _VoidIntC = Void Function(Int32);
typedef _VoidInt = void Function(int);
typedef _IntIntC = Int32 Function(Int32);
typedef _IntInt = int Function(int);
typedef _VoidArrC = Void Function(Pointer<Int32>);
typedef _VoidArr = void Function(Pointer<Int32>);
typedef _VoidIntArrC = Void Function(Int32, Pointer<Int32>);
typedef _VoidIntArr = void Function(int, Pointer<Int32>);
typedef _IntPtrIntC = Int32 Function(Pointer<Void>, Int32);
typedef _IntPtrInt = int Function(Pointer<Void>, int);
typedef _VoidPtrIntIntC = Void Function(Pointer<Void>, Int32, Int32);
typedef _VoidPtrIntInt = void Function(Pointer<Void>, int, int);
typedef _HistStrC = Void Function(Pointer<Void>, Pointer<Uint8>, Int32);
typedef _HistStr = void Function(Pointer<Void>, Pointer<Uint8>, int);

DynamicLibrary _open() {
  // iOS/macOS: symbols are in the process. Others: a named shared library.
  return DynamicLibrary.process();
}

/// A single M12 game (an opaque MathieuPermutationWithHistory on the C++ side).
class MathieuEngine {
  static final DynamicLibrary _lib = _open();

  static final _new = _lib.lookupFunction<_NewC, _NewDart>('mathieu_new');
  static final _free = _lib.lookupFunction<_FreeC, _Free>('mathieu_free');
  static final _numBalls = _lib.lookupFunction<_IntVoidC, _IntVoid>('mathieu_num_balls');
  static final _numSwaps = _lib.lookupFunction<_IntVoidC, _IntVoid>('mathieu_num_swaps');
  static final _reset = _lib.lookupFunction<_VoidPtrC, _VoidPtr>('mathieu_reset');
  static final _left = _lib.lookupFunction<_VoidPtrIntC, _VoidPtrInt>('mathieu_left');
  static final _right = _lib.lookupFunction<_VoidPtrIntC, _VoidPtrInt>('mathieu_right');
  static final _swap = _lib.lookupFunction<_VoidPtrC, _VoidPtr>('mathieu_swap');
  static final _random = _lib.lookupFunction<_VoidPtrC, _VoidPtr>('mathieu_random');
  static final _undo = _lib.lookupFunction<_IntPtrIntC, _IntPtrInt>('mathieu_undo');
  static final _revert = _lib.lookupFunction<_VoidPtrC, _VoidPtr>('mathieu_revert');
  static final _moves = _lib.lookupFunction<_IntPtrC, _IntPtr>('mathieu_moves');
  static final _steps = _lib.lookupFunction<_IntPtrC, _IntPtr>('mathieu_steps');
  static final _eraseAll = _lib.lookupFunction<_VoidPtrC, _VoidPtr>('mathieu_erase_all_macros');
  static final _arrangement = _lib.lookupFunction<_VoidPtrArrC, _VoidPtrArr>('mathieu_get_arrangement');
  static final _histLen = _lib.lookupFunction<_IntPtrC, _IntPtr>('mathieu_history_length');
  static final _solved = _lib.lookupFunction<_IntPtrC, _IntPtr>('mathieu_is_solved');
  static final _setSwapIndex = _lib.lookupFunction<_VoidIntC, _VoidInt>('mathieu_set_swap_index');
  static final _getSwapIndex = _lib.lookupFunction<_IntVoidC, _IntVoid>('mathieu_get_swap_index');
  static final _swapDifficulty = _lib.lookupFunction<_IntIntC, _IntInt>('mathieu_swap_difficulty');
  static final _swapPerm = _lib.lookupFunction<_VoidArrC, _VoidArr>('mathieu_get_swap_permutation');
  static final _swapPermAt = _lib.lookupFunction<_VoidIntArrC, _VoidIntArr>('mathieu_get_swap_permutation_at');
  static final _macroDefined = _lib.lookupFunction<_IntPtrIntC, _IntPtrInt>('mathieu_macro_defined');
  static final _anyMacro = _lib.lookupFunction<_IntPtrC, _IntPtr>('mathieu_any_macro_defined');
  static final _setMacro = _lib.lookupFunction<_VoidPtrIntC, _VoidPtrInt>('mathieu_set_macro');
  static final _eraseMacro = _lib.lookupFunction<_VoidPtrIntC, _VoidPtrInt>('mathieu_erase_macro');
  static final _runMacro = _lib.lookupFunction<_VoidPtrIntIntC, _VoidPtrIntInt>('mathieu_run_macro');
  static final _histStr = _lib.lookupFunction<_HistStrC, _HistStr>('mathieu_history_str');
  static final _histIsSingleMacro = _lib.lookupFunction<_IntPtrIntC, _IntPtrInt>('mathieu_history_is_single_macro');

  static int get ballCount => _numBalls();
  static int get swapCount => _numSwaps();
  static int get swapIndex => _getSwapIndex();
  static set swapIndex(int i) => _setSwapIndex(i);
  static int swapDifficulty(int i) => _swapDifficulty(i);

  final Pointer<Void> _h;
  final int n;
  MathieuEngine()
      : _h = _new(),
        n = _numBalls();

  void dispose() => _free(_h);

  void reset() => _reset(_h);
  void left([int count = 1]) => _left(_h, count);
  void right([int count = 1]) => _right(_h, count);
  void swap() => _swap(_h);
  void random() => _random(_h);
  bool undo({bool move = true}) => _undo(_h, move ? 1 : 0) != 0;
  void revert() => _revert(_h);
  void eraseAllMacros() => _eraseAll(_h);
  int get historyLength => _histLen(_h);
  int get moves => _moves(_h);
  int get steps => _steps(_h);
  bool get isSolved => _solved(_h) != 0;

  /// arrangement[i] = ball value currently at ring position i.
  List<int> arrangement() => _readArray(n, (p) => _arrangement(_h, p));

  /// current swap permutation (six disjoint 2-cycles), keyed by ball value.
  static List<int> swapPermutation(int n) => _readArray(n, _swapPerm);

  /// swap permutation #i (for the selector), without changing the selection.
  static List<int> swapPermutationAt(int i, int n) =>
      _readArray(n, (p) => _swapPermAt(i, p));

  // --- macros (A..E => codes 65..69) ---
  bool macroDefined(int c) => _macroDefined(_h, c) != 0;
  bool get anyMacroDefined => _anyMacro(_h) != 0;
  void setMacro(int c) => _setMacro(_h, c);
  void eraseMacro(int c) => _eraseMacro(_h, c);
  void runMacro(int c, {bool inverted = false}) => _runMacro(_h, c, inverted ? 1 : 0);
  bool historyIsSingleMacro(int c) => _histIsSingleMacro(_h, c) != 0;

  /// Move-history notation for the status line, e.g. "L2 S R3 A".
  String historyStr() {
    final buf = calloc<Uint8>(256);
    try {
      _histStr(_h, buf, 256);
      return buf.cast<Utf8>().toDartString();
    } finally {
      calloc.free(buf);
    }
  }

  static List<int> _readArray(int n, void Function(Pointer<Int32>) fill) {
    final p = calloc<Int32>(n);
    try {
      fill(p);
      return List<int>.generate(n, (i) => p[i]);
    } finally {
      calloc.free(p);
    }
  }
}
