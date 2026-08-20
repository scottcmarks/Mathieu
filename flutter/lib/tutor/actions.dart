// What the tutorial pages are allowed to ask the board to do.
//
// The pages live on the "back of the game" and the board lives on the front, so
// every one of these returns to the board first. Keeping the surface this small
// is what stops the tutorial from reaching into _GamePageState.

import '../m12/library.dart';
import '../m12/word.dart';
import '../mathieu_ffi.dart';
import '../skin/skin.dart';
import 'brain.dart';

abstract class TutorActions {
  MathieuEngine get game;
  M12Brain get brain;
  Skin get skin;

  /// arrangement[i] = the piece at seat i, right now.
  List<int> get arrangement;

  /// True once the puzzle has been scrambled and not yet brought home.
  bool get isSolving;

  /// Return to the board and play [word] there.
  ///
  /// [stepped] runs it one primitive move at a time with a transport bar;
  /// otherwise it lands in a single animated move. [highlight] is the set of
  /// seats to call out for the duration — normally the word's own support, so
  /// the point of a 3+3+3 is visible while it runs.
  Future<void> playWord(
    Word word, {
    String label,
    Set<int> highlight,
    bool stepped,
  });

  /// Return to the board and run engine register [slot] (65..69).
  Future<void> runSlot(int slot, {bool inverted});

  /// Bind a library entry to a register, or clear one.
  Future<void> bindSlot(int slot, MacroEntry entry);
  Future<void> unbindSlot(int slot);

  /// Return to the board, at home.
  Future<void> goHome();

  /// Return to the board scrambled to exactly [moves] away from home, so a
  /// lesson can say "you are nine moves out" and mean it.
  Future<void> scrambleToDistance(int moves);

  /// The word the user has played since the solve began, as the engine reduced
  /// it. This is what "record what I just did" saves.
  Word get currentWord;
}
