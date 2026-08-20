# Macros and the tutorial

The reason this app exists alongside the physical toy.

A mechanical M12 toy can do everything the group can do — it *is* the group. What
it cannot do is **remember**, **count**, **search**, or **explain**. Every
feature here is one of those four, and each lesson names the one it is.

> The engine already had bare macros: five keys, long-press to record, tap to
> play, Alt to play the inverse. That was the seed. This document describes what
> grew from it.

## The maths, in one paragraph

The puzzle is the sporadic Mathieu group **M₁₂** acting on 12 numbered pieces.
Two generators: **r** (spin), an 11-cycle on the ring seats that fixes the
outboard seat, and **s** (swap), an involution. Everything the app does is a
word in r and s. The group has order **95,040**; with the app's default swap the
diameter is 11 moves. M₁₂ contains **no 3-cycles at all** — the gentlest thing
you can do moves eight seats — which is the fact lesson 5 is built around.

## The pieces of the feature

| Piece | Where | What it is |
|---|---|---|
| `Word` | `lib/m12/word.dart` | a sequence in r and s, kept in the engine's own reduced form |
| `MacroAnalysis` | `lib/m12/analysis.dart` | cycles, shape, support, fixed seats, order, distance, plain English |
| `M12Table` | `lib/m12/table.dart` | God's-algorithm BFS over all 95,040 positions |
| `Discovery` | `lib/m12/search.dart` | cheapest representative of each cycle shape |
| `MacroLibrary` | `lib/m12/library.dart` | named, persisted macros; five engine keys bind to entries |
| `M12Brain` | `lib/tutor/brain.dart` | owns table, discovery and library; binds words to engine slots |
| Lessons / Workshop / Library | `lib/tutor/` | the three things behind the **Learn** button |

`Word` is a faithful port of the C++ `History` (`m.h`): adjacent runs merge, a
full turn vanishes, two swaps cancel, and a macro next to its own inverse
cancels. That identity is checked against 300 fixture rows replayed through the
real engine, in both notations and at two different swaps.

### Words and macro letters

An element of a word is a signed int in the engine's encoding: `-11..-1` a left
run, `0` the swap, `1..11` a right run, `65..69` macro A..E (negative = its
inverse).

A macro letter is **not** a move. Anything that plays, prices or expands a word
must be given the macro map so the letter can be resolved:

```dart
w.primitiveSteps(macros: _macroWords)   // play it
w.steps(macros: _macroWords)            // price it
w.expanded(_macroWords)                 // flatten it
w.permutation(swap: s, macros: …)       // analyse it
```

All four **skip** an unresolved letter rather than throwing, so a stale library
entry can still be displayed. They must agree on that: a word that analyses as
one element and plays as another is the bug below.

> **Fixed, and pinned by `test/m12_group_test.dart`.** `primitiveSteps` used to
> fall through to the raw element for a macro letter, handing `65` to callers
> that all do `right(e)` — and the engine reduces a run modulo the ring, so
> `right(65)` is **R10**. A booklet QR of `#word=A` spun the ring ten wedges and
> called it a macro. Worse, `permutation` skipped the same letter, so the word
> analysed as the identity while it played as R10. Both halves now expand, with
> a depth guard so a cyclic definition terminates instead of hanging the UI.

### What a macro records

`mathieu_set_macro` stores **start⁻¹ · current** — the word you played, not "the
scramble and then the word you played". Without that division, a macro recorded
mid-solve would carry the scramble inside it, `run_macro` would re-apply it, and
every analysis shown would be about the wrong element. The original
Objective-C++ app divided the scramble out (`GameModel.mm`); the Flutter port
had dropped it, and the C handle now keeps a `start` permutation to restore it.

`mathieu_set_macro_from` binds a word replayed on a throwaway handle, so the
live game's history is untouched — you can bind a macro mid-solve without it
looking like you played anything.

Rebinding or erasing a key **rewrites history in place** (`R A` becomes
`R3 S`), so position, history and `currentWord` stay consistent.

> **This reaches the watch.** `watch/project.yml` compiles
> `../flutter/native/mathieu_ffi.cpp` directly and `MathieuEngine.swift` calls
> `mathieu_set_macro`, so the watch picks up the corrected semantics even though
> it has no tutorial UI. That is the fix, not a regression — but it ships to the
> watch without the watch asking for it.

## The five keys

`A`..`E`, with `Alt` to run an inverse. The history strip writes an inverse
macro as `A⁻¹`.

- **Tap** — run the key (with `Alt`, run its inverse).
- **Long press** — with **Confirmation** on, open the key sheet: what the key
  means now, what it would come to mean, and buttons to step through it, save it
  to the library, redefine or erase it. With **Confirmation** off, define it in
  one gesture, which is what that preference has always bought.

The sheet is the tutorial's answer to "what did I just record?" — it is a full
`MacroAnalysis`, not a yes/no.

## The lesson curriculum

Ten lessons, plus a skin-gated opener. Each carries a `toyCant` line, which is
the editorial rule: **if a mechanical toy could do it, it is not a lesson.**

| # | Title | What it teaches | What the toy cannot do |
|---|---|---|---|
| 0 | Meet the machine | the mechanism you are holding is *one move* | show you that its whole dance is a single atomic swap |
| 1 | The two moves | spin and swap generate everything | annotate itself |
| 2 | Two moves, 95,040 positions | the size of the group, the distance histogram, the diameter | count its own states, or know how far from home it is |
| 3 | Undo, and inverse | every move and every sequence has an opposite | spell out the opposite of what you just did |
| 4 | Record your own macro | a macro is the *moves*, not the position | remember anything at all |
| 5 | How little can you disturb? | M₁₂ has no 3-cycles; the minimum support is 8 | search its own move space |
| 6 | Aim it — conjugation | X·M·X⁻¹ moves an element onto the seats you choose | find the setup word for you |
| 7 | Commutators | where two moves disagree, and why that is small | compare its own constructions |
| 8 | A working tool | the last three together as a kit | hand you a tool kit |
| 9 | Finish a real scramble | solving with distance-to-home after every move | tell you whether you are getting closer |
| 10 | Your library | five keys, unlimited macros, 341 swaps | keep your notes for you |

Lesson 0 is `skinGated`: it ships and hides with a device pack, because it talks
about the machine in front of you. Lessons 2, 4, 9 need the BFS table; 5–8 also
need the group-wide search. Both are built in the background from app start, so
the first visit to **Learn** is not a wait.

Every number a lesson states is computed at runtime from the table or the
search — none is written into the prose. The distance histogram, the diameter
and the cycle-shape census come out of the same BFS the solver uses.

## Workshop

Free-form, for when the lessons are done: **Inverse**, **Composition**,
**Commutator [A, B]**, **Aim it (conjugation)**, and **the search** — cheapest
representative of each cycle shape under the swap in force. Conjugation setups
are distance-minimal: brute-forced over all 220 seat-triples, there is no
cheaper joined word.

## Library

Named macros, persisted through `shared_preferences`. Each entry records the
**swap index** it was written under, because a word means a different element
under a different swap — entries from another swap are listed after yours and
are never auto-bound. Binding is stored, so the five keys survive a relaunch.

Library words are stored **expanded** (letter-free), so an entry keeps its
meaning after a key is rebound underneath it.

## Deep links — the booklet formats

One grammar, two carriers, one parser (`lib/deeplink.dart`), so a printed QR
cannot drift from what the app accepts:

    web     https://magnolia-heights.com/sporadicgames/m12/#skin=<id>&lesson=<n>&swap=<i>&word=<w>
    mobile  m12://open?skin=<id>&lesson=<n>&swap=<i>&word=<w>

| key | meaning | applied |
|---|---|---|
| `skin` | pack id | in `runMathieu()`, before the first frame |
| `swap` | swap index, 0–340 | in `runMathieu()`, before the first frame |
| `lesson` | lesson number | on the first frame, pushed over the board |
| `word` | a word in the generators, e.g. `R3SL2S` | on the first frame, replayed into the game |

**Resolution is deliberately forgiving, because a printed QR cannot be
recalled.** An unknown or gated skin degrades *silently* to the default (it must
not reveal that the pack exists), an out-of-range lesson clamps, a swap outside
0–340 is ignored, and an unparseable word is dropped. A malformed URL never
keeps the app from starting.

**Word grammar:** `L`, `R`, `S` with optional repeat counts (`L2`, `R3`), and
the macro letters `A`–`E`. The parser accepts `A^-1` and `A⁻¹` for an inverse
macro. Note the deep-link reader upper-cases the whole word, so the lowercase
spelling of an inverse (`a`) does **not** survive a link — print `A^-1`.

A word naming a macro key resolves against the keys as they are *at that
moment*; on a fresh launch nothing is defined, so `#word=A` correctly does
nothing. Booklet words meant to reproduce a position should be spelled out in
`L`/`R`/`S`.

**Flutter web eats the fragment.** The default hash URL strategy treats `#…` as
the route and clears it before Dart's `main()` runs. `web/index.html` moves the
fragment into the query string with `history.replaceState` before
`flutter_bootstrap.js` loads: the router leaves the query alone, a static host
still ignores it, and no reload happens. `fromCurrentUrl()` accepts either
carrier, so the printed `#…` URL keeps working.

Booklet URLs naming a gated skin are **printable now** — they degrade silently
until the pack ships. The print schedule does not have to wait on the filing.
See `SKINS.md`.

### Not yet wired

- The `m12:` custom scheme itself: no `CFBundleURLTypes` in the iOS/macOS
  `Info.plist`, no `<intent-filter>` in `AndroidManifest.xml`, no `app_links`
  dependency. The grammar and parser are in place for both carriers.
- `onHashChange`, so scanning a booklet QR against an already-open tab needs a
  reload.

## Tests

| file | covers |
|---|---|
| `test/m12_group_test.dart` | the port against 300 engine fixture rows at two swaps; macro-letter expansion; conjugation over all 220 triples; the table against `perms.lst` |
| `test/engine_ffi_test.dart` | the Dart↔C++ contract through the real bindings (needs `MATHIEU_ENGINE_LIB`) |
| `test/m12_library_test.dart` | library persistence and swap-scoped bindings |
| `test/deeplink_test.dart` | both carriers, and silent degradation of a gated skin |
| `test/macro_key_ui_test.dart` | the key sheet, the Confirmation preference, and the screen around the ring |

The FFI and UI tests skip unless the engine is built as a shared library:

    ./tool/build_native_test_lib.sh
    MATHIEU_ENGINE_LIB="$PWD/build/native-test/libmathieu_engine.dylib" flutter test
