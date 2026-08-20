// Web implementation of the M12 engine API, calling the Emscripten WASM module
// through thin wrappers in web/mathieu_glue.js.
import 'dart:js_interop';

@JS('mathieuWasmInit') external JSPromise<JSAny?> _jsInit();
@JS('mathieuNumBalls') external int _numBalls();
@JS('mathieuNumSwaps') external int _numSwaps();
@JS('mathieuNew') external int _new();
@JS('mathieuFree') external void _free(int h);
@JS('mathieuReset') external void _reset(int h);
@JS('mathieuLeft') external void _left(int h);
@JS('mathieuRight') external void _right(int h);
@JS('mathieuSwap') external void _swap(int h);
@JS('mathieuRandom') external void _random(int h);
@JS('mathieuUndo') external int _undo(int h, int move);
@JS('mathieuRevert') external void _revert(int h);
@JS('mathieuMoves') external int _moves(int h);
@JS('mathieuSteps') external int _steps(int h);
@JS('mathieuHistoryLength') external int _histLen(int h);
@JS('mathieuIsSolved') external int _solved(int h);
@JS('mathieuArrangement') external JSArray<JSNumber> _arr(int h);
@JS('mathieuSwapPermutation') external JSArray<JSNumber> _sp();
@JS('mathieuSwapPermutationAt') external JSArray<JSNumber> _spAt(int i);
@JS('mathieuSetSwapIndex') external void _setSwapIndex(int i);
@JS('mathieuGetSwapIndex') external int _getSwapIndex();
@JS('mathieuSwapDifficulty') external int _swapDiff(int i);
@JS('mathieuMacroDefined') external int _macroDef(int h, int c);
@JS('mathieuAnyMacro') external int _anyMacro(int h);
@JS('mathieuSetMacro') external void _setMacro(int h, int c);
@JS('mathieuEraseMacro') external void _eraseMacro(int h, int c);
@JS('mathieuEraseAllMacros') external void _eraseAll(int h);
@JS('mathieuRunMacro') external void _runMacro(int h, int c, int inv);
@JS('mathieuHistoryIsSingleMacro') external int _histSingle(int h, int c);
@JS('mathieuHistoryStr') external JSString _histStr(int h);
@JS('mathieuMacroPermutation') external JSArray<JSNumber>? _macroPerm(int h, int c);
@JS('mathieuMacroHistoryStr') external JSString _macroStr(int h, int c);
@JS('mathieuSetMacroFrom') external void _setMacroFrom(int h, int c, int src);
@JS('mathieuGetStart') external JSArray<JSNumber> _getStart(int h);
@JS('mathieuSetPosition') external int _setPosition(int h, JSArray<JSNumber> perm);

Future<void> initMathieu() async {
  await _jsInit().toDart;
}

List<int> _toList(JSArray<JSNumber> a) =>
    a.toDart.map((e) => e.toDartInt).toList();

class MathieuEngine {
  final int _h;
  final int n;
  MathieuEngine()
      : _h = _new(),
        n = _numBalls();

  void dispose() => _free(_h);

  static int get ballCount => _numBalls();
  static int get swapCount => _numSwaps();
  static int get swapIndex => _getSwapIndex();
  static set swapIndex(int i) => _setSwapIndex(i);
  static int swapDifficulty(int i) => _swapDiff(i);
  static List<int> swapPermutation(int n) => _toList(_sp());
  static List<int> swapPermutationAt(int i, int n) => _toList(_spAt(i));

  void reset() => _reset(_h);
  void left([int count = 1]) {
    for (var i = 0; i < count; i++) _left(_h);
  }
  void right([int count = 1]) {
    for (var i = 0; i < count; i++) _right(_h);
  }
  void swap() => _swap(_h);
  void random() => _random(_h);
  bool undo({bool move = true}) => _undo(_h, move ? 1 : 0) != 0;
  void revert() => _revert(_h);
  void eraseAllMacros() => _eraseAll(_h);
  int get historyLength => _histLen(_h);
  int get moves => _moves(_h);
  int get steps => _steps(_h);
  bool get isSolved => _solved(_h) != 0;
  List<int> arrangement() => _toList(_arr(_h));
  bool macroDefined(int c) => _macroDef(_h, c) != 0;
  bool get anyMacroDefined => _anyMacro(_h) != 0;
  void setMacro(int c) => _setMacro(_h, c);
  void eraseMacro(int c) => _eraseMacro(_h, c);
  void runMacro(int c, {bool inverted = false}) => _runMacro(_h, c, inverted ? 1 : 0);
  bool historyIsSingleMacro(int c) => _histSingle(_h, c) != 0;
  String historyStr() => _histStr(_h).toDart;

  // --- macro introspection: same contract as the dart:ffi path ---
  List<int>? macroPermutation(int c) {
    final a = _macroPerm(_h, c);
    return a == null ? null : _toList(a);
  }

  String macroWord(int c) => _macroStr(_h, c).toDart;
  void setMacroFrom(int c, MathieuEngine src) => _setMacroFrom(_h, c, src._h);
  List<int> start() => _toList(_getStart(_h));

  bool setPosition(List<int> perm) =>
      _setPosition(_h, perm.map((e) => e.toJS).toList().toJS) != 0;
}
