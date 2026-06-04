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
  static final _undo = _lib.lookupFunction<_IntPtrC, _IntPtr>('mathieu_undo');
  static final _arrangement = _lib.lookupFunction<_VoidPtrArrC, _VoidPtrArr>('mathieu_get_arrangement');
  static final _histLen = _lib.lookupFunction<_IntPtrC, _IntPtr>('mathieu_history_length');
  static final _solved = _lib.lookupFunction<_IntPtrC, _IntPtr>('mathieu_is_solved');
  static final _setSwapIndex = _lib.lookupFunction<_VoidIntC, _VoidInt>('mathieu_set_swap_index');
  static final _getSwapIndex = _lib.lookupFunction<_IntVoidC, _IntVoid>('mathieu_get_swap_index');
  static final _swapDifficulty = _lib.lookupFunction<_IntIntC, _IntInt>('mathieu_swap_difficulty');
  static final _swapPerm = _lib.lookupFunction<_VoidArrC, _VoidArr>('mathieu_get_swap_permutation');

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
  bool undo() => _undo(_h) != 0;
  int get historyLength => _histLen(_h);
  bool get isSolved => _solved(_h) != 0;

  /// arrangement[i] = ball value currently at ring position i.
  List<int> arrangement() => _readArray(n, (p) => _arrangement(_h, p));

  /// current swap permutation (six disjoint 2-cycles), keyed by ball value.
  static List<int> swapPermutation(int n) => _readArray(n, _swapPerm);

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
