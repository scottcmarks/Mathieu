// Dart FFI bindings for the Mathieu "M12" C++ engine.
//
// On iOS/macOS the engine is compiled into the app binary, so we load it with
// DynamicLibrary.process(). On Android/Linux/Windows it ships as a shared lib.
// (Web uses a separate js_interop path — added later.)

import 'dart:ffi';
import 'dart:io' show Platform;
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
typedef _MacroPermC = Int32 Function(Pointer<Void>, Int32, Pointer<Int32>);
typedef _MacroPerm = int Function(Pointer<Void>, int, Pointer<Int32>);
typedef _MacroStrC = Void Function(Pointer<Void>, Int32, Pointer<Uint8>, Int32);
typedef _MacroStr = void Function(Pointer<Void>, int, Pointer<Uint8>, int);
typedef _SetPositionC = Int32 Function(Pointer<Void>, Pointer<Int32>);
typedef _SetPosition = int Function(Pointer<Void>, Pointer<Int32>);
typedef _SetMacroFromC = Void Function(Pointer<Void>, Int32, Pointer<Void>);
typedef _SetMacroFrom = void Function(Pointer<Void>, int, Pointer<Void>);

DynamicLibrary _open() {
  // A standalone Dart VM (dart test / flutter test) has no engine linked in, so
  // there is nothing for DynamicLibrary.process() to find. Naming a built
  // library here lets these same bindings — not a copy of them — be exercised
  // against the real C++ from a test. See tool/build_native_test_lib.sh.
  const override = String.fromEnvironment('MATHIEU_ENGINE_LIB');
  final path = override.isNotEmpty
      ? override
      : Platform.environment['MATHIEU_ENGINE_LIB'] ?? '';
  if (path.isNotEmpty) return DynamicLibrary.open(path);

  // iOS/macOS: the engine is compiled into the app, so symbols are in-process.
  // Android/Linux: a shared object; Windows: a DLL.
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('libmathieu_engine.so');
  }
  if (Platform.isWindows) return DynamicLibrary.open('mathieu_engine.dll');
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
  static final _macroPerm =
      _lib.lookupFunction<_MacroPermC, _MacroPerm>('mathieu_macro_permutation');
  static final _macroStr =
      _lib.lookupFunction<_MacroStrC, _MacroStr>('mathieu_macro_history_str');
  static final _setMacroFrom =
      _lib.lookupFunction<_SetMacroFromC, _SetMacroFrom>('mathieu_set_macro_from');
  static final _getStart = _lib.lookupFunction<_VoidPtrArrC, _VoidPtrArr>('mathieu_get_start');
  static final _setPosition =
      _lib.lookupFunction<_SetPositionC, _SetPosition>('mathieu_set_position');

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

  /// The permutation macro [c] applies, or null if [c] is not defined. The
  /// position the macro was recorded from has been divided out, so this agrees
  /// with [macroWord] even for a macro set part-way through a scrambled puzzle.
  List<int>? macroPermutation(int c) {
    final p = calloc<Int32>(n);
    try {
      if (_macroPerm(_h, c, p) == 0) return null;
      return List<int>.generate(n, (i) => p[i]);
    } finally {
      calloc.free(p);
    }
  }

  /// Macro [c]'s own word, in the same notation as [historyStr]. Empty if unset.
  String macroWord(int c) => _readStr((b, cap) => _macroStr(_h, c, b, cap));

  /// Define macro [c] here as the game [src] holds — how a library entry is
  /// bound to a key: replay its word on a scratch engine, then bind that.
  void setMacroFrom(int c, MathieuEngine src) => _setMacroFrom(_h, c, src._h);

  /// The position this solve started from: identity after [reset], the scramble
  /// after [random]. What [setMacro] divides out.
  List<int> start() => _readArray(n, (p) => _getStart(_h, p));

  /// Put the board at [perm] with an empty history, keeping macro definitions.
  /// False if [perm] is not a permutation of 0..n-1.
  bool setPosition(List<int> perm) {
    final p = calloc<Int32>(n);
    try {
      for (var i = 0; i < n; i++) {
        p[i] = perm[i];
      }
      return _setPosition(_h, p) != 0;
    } finally {
      calloc.free(p);
    }
  }

  /// Move-history notation for the status line, e.g. "L2 S R3 A".
  String historyStr() => _readStr((b, cap) => _histStr(_h, b, cap));

  // A macro-heavy session ran past the old 256-byte cap and truncated silently.
  static const _strCap = 1024;

  static String _readStr(void Function(Pointer<Uint8>, int) fill) {
    final buf = calloc<Uint8>(_strCap);
    try {
      fill(buf, _strCap);
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

// No async engine load needed off the web (engine is in-process / a shared lib).
Future<void> initMathieu() async {}
