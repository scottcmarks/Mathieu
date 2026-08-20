//
//  mathieu_ffi.cpp
//  Thin C ABI over the Mathieu "M12" C++ engine, for Dart FFI.
//
//  Mirrors the role of SudokuX4's native/sudoku_ffi.cpp: an opaque
//  handle (a MathieuPermutationWithHistory*) plus plain C functions.
//
//  Include via m12.h (NOT m.h directly): m12.h #defines nBalls/nSwaps,
//  which m.h references as bare tokens, then pulls in the permutation
//  base and m.h itself.
//

#include "m12.h"
#include "mathieu_ffi.h"
#include <string>
#include <cstring>

#if defined(_WIN32)
  #define FFI_EXPORT __declspec(dllexport)
#elif defined(__EMSCRIPTEN__)
  #include <emscripten/emscripten.h>
  #define FFI_EXPORT EMSCRIPTEN_KEEPALIVE
#else
  // `used` keeps the symbol from being dead-stripped when compiled into an
  // app binary (iOS/macOS) where no native code references these entry points.
  #define FFI_EXPORT __attribute__((visibility("default"), used))
#endif

typedef MathieuPermutationWithHistory Game;
typedef Game::HistoryElement HistoryElement;

// A handle is the game plus the position the current solve started from.
//
// Why `start` exists: random() scrambles the permutation to P0 and then wipes
// the history ("amnesia", m.h:595). Play a word W and the game holds P0*W while
// its history says only W. Defining a macro from that game would store a
// permutation and a word that disagree — run_macro would re-apply the scramble,
// and every analysis the tutorial shows would be about the wrong element. The
// original Objective-C++ app divided the scramble out (GameModel.mm:277-282);
// the Flutter port dropped it. `start` restores that.
struct Handle {
    Game g;
    MathieuPermutation start;   // identity after reset, the scramble after random
};

static inline Handle* H(void* h) { return static_cast<Handle*>(h); }
static inline Game*   G(void* h) { return &H(h)->g; }

// Reach the permutation half of a game without its history, so the two can be
// adjusted separately (the `as` trick from GameModel.mm:210).
static inline MathieuPermutation& as(Game& p) {
    return *reinterpret_cast<MathieuPermutation*>(&p);
}

static void put_str(const std::string& s, char* out, int cap) {
    if (cap <= 0) return;
    std::strncpy(out, s.c_str(), (size_t)cap - 1);
    out[cap - 1] = '\0';
}

extern "C" {

// --- lifecycle ---
FFI_EXPORT void* mathieu_new(void)        { return new Handle(); }
FFI_EXPORT void  mathieu_free(void* h)    { delete H(h); }

// --- constants ---
FFI_EXPORT int mathieu_num_balls(void)    { return nBalls; }
FFI_EXPORT int mathieu_num_swaps(void)    { return nSwaps; }

// --- moves ---
// reset() and random() both begin a new solve, so both re-anchor `start`.
FFI_EXPORT void mathieu_reset (void* h) {
    Handle* p = H(h);
    p->g.reset();
    p->start = MathieuPermutation();   // identity
}
FFI_EXPORT void mathieu_left  (void* h, int count) { G(h)->left((Index)count);  }
FFI_EXPORT void mathieu_right (void* h, int count) { G(h)->right((Index)count); }
FFI_EXPORT void mathieu_swap  (void* h)            { G(h)->swap();         }
FFI_EXPORT void mathieu_random(void* h) {
    Handle* p = H(h);
    p->g.random();
    p->start = as(p->g);               // history is empty, so this IS the start
}

// Undo one move (move!=0) or one step (move==0). Returns 1 if something was
// undone, 0 if the history was already empty.
FFI_EXPORT int mathieu_undo(void* h, int move) {
    Game* g = G(h);
    if (g->history_is_empty()) return 0;
    g->undo(move != 0);
    return 1;
}

// Revert to the scrambled start (random() leaves history empty, so undoing all
// moves returns to the scramble) while keeping macro definitions.
FFI_EXPORT void mathieu_revert(void* h) {
    Game* g = G(h);
    while (!g->history_is_empty()) g->undo(true);
}

FFI_EXPORT int mathieu_moves(void* h) { return G(h)->moves(); }
FFI_EXPORT int mathieu_steps(void* h) { return G(h)->steps(); }
FFI_EXPORT void mathieu_erase_all_macros(void* h) { G(h)->erase_all_macros(); }

// --- state queries ---
// Fills out[i] (i in 0..nBalls-1) with the ball value currently at ring position i.
FFI_EXPORT void mathieu_get_arrangement(void* h, int* out) {
    Game* g = G(h);
    for (int i = 0; i < nBalls; i++) out[i] = (int)(*g)[(Index)i];
}

FFI_EXPORT int mathieu_history_length  (void* h) { return G(h)->history_length(); }
FFI_EXPORT int mathieu_history_is_empty(void* h) { return G(h)->history_is_empty() ? 1 : 0; }
FFI_EXPORT int mathieu_is_solved       (void* h) { return G(h)->is_identity() ? 1 : 0; }

// --- swap-permutation selection (static, shared by all games) ---
FFI_EXPORT void mathieu_set_swap_index(int i) { MathieuPermutation::set_swapPermutationIndex(i); }
FFI_EXPORT int  mathieu_get_swap_index(void)  { return MathieuPermutation::swapPermutationIndex; }

// difficulty score of swap permutation i (the `best` field; large sentinel if out of range)
FFI_EXPORT int mathieu_swap_difficulty(int i) {
    if (i < 0 || i >= nSwaps) return -1;
    return (int)MathieuPermutation::swaps[i].best;
}

// Fills out[i] with the current swap permutation (six disjoint 2-cycles).
// Dart uses this to colour balls: each 2-cycle gets one palette colour.
FFI_EXPORT void mathieu_get_swap_permutation(int* out) {
    for (int i = 0; i < nBalls; i++) out[i] = (int)MathieuPermutation::swapPermutation[(Index)i];
}

// Fill out[0..nBalls-1] with swap permutation #i (without changing selection).
FFI_EXPORT void mathieu_get_swap_permutation_at(int i, int* out) {
    if (i < 0 || i >= nSwaps) return;
    const MathieuPermutation::PermArray& sp = MathieuPermutation::swaps[i].swap;
    for (int k = 0; k < nBalls; k++) out[k] = (int)sp[k];
}

// --- macros ("combos" A..E, stored per-game in the history) ---
FFI_EXPORT int mathieu_macro_defined(void* h, int c) {
    return G(h)->macro_is_defined((HistoryElement)c) ? 1 : 0;
}
FFI_EXPORT int mathieu_any_macro_defined(void* h) {
    return G(h)->any_macro_is_defined() ? 1 : 0;
}
// Define macro c as the word played so far; if the history is empty, erase it.
//
// The definition is start^-1 * current, so a macro recorded part-way through a
// scrambled puzzle means the moves you played, not "the scramble and then the
// moves you played". Its permutation then agrees with its word, which every
// analysis in the tutorial depends on.
FFI_EXPORT void mathieu_set_macro(void* h, int c) {
    Handle* p = H(h);
    Game& g = p->g;
    if (g.history_is_empty()) { g.erase_macro((HistoryElement)c); return; }
    // set_macro's own first act is to rewrite every existing occurrence of c
    // with c's *old* meaning. Do it before taking the copy, or the copy would
    // capture a self-reference that the rewrite is meant to remove.
    g.expand_macro((HistoryElement)c);
    Game def(g);
    as(def) = p->start.inverse() * as(def);
    g.set_macro((HistoryElement)c, def);   // the second expand_macro is a no-op
}

// Define macro c on h as the game held by src (with src's own start divided out
// the same way). Lets Dart replay an arbitrary word on a scratch handle and bind
// the result, without a word parser in C and without touching h's history.
FFI_EXPORT void mathieu_set_macro_from(void* h, int c, void* src) {
    Handle* p = H(h);
    Handle* s = H(src);
    Game def(s->g);
    as(def) = s->start.inverse() * as(def);
    p->g.set_macro((HistoryElement)c, def);
}
FFI_EXPORT void mathieu_erase_macro(void* h, int c) { G(h)->erase_macro((HistoryElement)c); }
FFI_EXPORT void mathieu_run_macro(void* h, int c, int inverted) {
    G(h)->run_macro((HistoryElement)c, inverted != 0);
}
FFI_EXPORT int mathieu_history_is_single_macro(void* h, int c) {
    return G(h)->history_is_single_macro((HistoryElement)c) ? 1 : 0;
}

// --- status line: the move-history notation, e.g. "L2 S R3 A" ---
} // extern "C"

typedef MathieuPermutationWithHistory::History Hist;

static std::string format_history(const Hist& hist) {
    std::string s;
    for (Hist::const_iterator p = hist.begin(); p != hist.end(); ++p) {
        HistoryElement e = *p;
        if (Hist::is_swap(e)) {
            s += "S";
        } else if (Hist::is_left(e)) {
            s += "L";
            int n = -e; if (n > 1) s += std::to_string(n);
        } else if (Hist::is_right(e)) {
            s += "R";
            int n = e; if (n > 1) s += std::to_string(n);
        } else {
            // macro: positive = A..E, negative = inverse (shown lowercase)
            s += (e < 0) ? (char)('a' + ((-e) - 'A')) : (char)e;
        }
        s += ' ';
    }
    return s;
}

extern "C" {

FFI_EXPORT void mathieu_history_str(void* h, char* out, int cap) {
    put_str(format_history(G(h)->getHistory()), out, cap);
}

// --- macro introspection ---

FFI_EXPORT int mathieu_macro_permutation(void* h, int c, int* out) {
    Game& g = *G(h);
    if (!g.macro_is_defined((HistoryElement)c)) return 0;
    Hist hist = g.getHistory();
    Game def = hist.macro_definition((HistoryElement)c);
    for (int i = 0; i < nBalls; i++) out[i] = (int)def[(Index)i];
    return 1;
}

FFI_EXPORT void mathieu_macro_history_str(void* h, int c, char* out, int cap) {
    Game& g = *G(h);
    if (!g.macro_is_defined((HistoryElement)c)) { put_str(std::string(), out, cap); return; }
    Hist hist = g.getHistory();
    put_str(format_history(hist.macro_definition((HistoryElement)c).getHistory()), out, cap);
}

FFI_EXPORT void mathieu_get_start(void* h, int* out) {
    const MathieuPermutation& s = H(h)->start;
    for (int i = 0; i < nBalls; i++) out[i] = (int)s[(Index)i];
}

FFI_EXPORT int mathieu_set_position(void* h, const int* perm) {
    bool used[nBalls] = { false };
    for (int i = 0; i < nBalls; i++) {
        const int v = perm[i];
        if (v < 0 || v >= nBalls || used[v]) return 0;
        used[v] = true;
    }
    MathieuPermutation::PermArray a;
    for (int i = 0; i < nBalls; i++) a[i] = (Index)perm[i];

    Handle* p = H(h);
    // reset() clears the history but keeps the macro map (History::reset only
    // resizes the element vector), which is what we want: the position changes,
    // the definitions you built do not.
    p->g.reset();
    as(p->g) = MathieuPermutation(a);
    p->start = as(p->g);
    return 1;
}

} // extern "C"
