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
static inline Game* G(void* h) { return static_cast<Game*>(h); }

extern "C" {

// --- lifecycle ---
FFI_EXPORT void* mathieu_new(void)        { return new Game(); }
FFI_EXPORT void  mathieu_free(void* h)    { delete G(h); }

// --- constants ---
FFI_EXPORT int mathieu_num_balls(void)    { return nBalls; }
FFI_EXPORT int mathieu_num_swaps(void)    { return nSwaps; }

// --- moves ---
FFI_EXPORT void mathieu_reset (void* h)            { G(h)->reset();        }
FFI_EXPORT void mathieu_left  (void* h, int count) { G(h)->left((Index)count);  }
FFI_EXPORT void mathieu_right (void* h, int count) { G(h)->right((Index)count); }
FFI_EXPORT void mathieu_swap  (void* h)            { G(h)->swap();         }
FFI_EXPORT void mathieu_random(void* h)            { G(h)->random();       }

// Returns 1 if a move was undone, 0 if the history was already empty.
FFI_EXPORT int mathieu_undo(void* h) {
    Game* g = G(h);
    if (g->history_is_empty()) return 0;
    g->undo();
    return 1;
}

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
// Define macro c as the current game; if the history is empty, erase it instead.
FFI_EXPORT void mathieu_set_macro(void* h, int c) {
    Game* g = G(h);
    if (g->history_is_empty()) g->erase_macro((HistoryElement)c);
    else g->set_macro((HistoryElement)c, *g);
}
FFI_EXPORT void mathieu_erase_macro(void* h, int c) { G(h)->erase_macro((HistoryElement)c); }
FFI_EXPORT void mathieu_run_macro(void* h, int c, int inverted) {
    G(h)->run_macro((HistoryElement)c, inverted != 0);
}
FFI_EXPORT int mathieu_history_is_single_macro(void* h, int c) {
    return G(h)->history_is_single_macro((HistoryElement)c) ? 1 : 0;
}

// --- status line: the move-history notation, e.g. "L2 S R3 A" ---
FFI_EXPORT void mathieu_history_str(void* h, char* out, int cap) {
    typedef MathieuPermutationWithHistory::History Hist;
    Hist hist = G(h)->getHistory();
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
    if (cap > 0) { std::strncpy(out, s.c_str(), cap - 1); out[cap - 1] = '\0'; }
}

} // extern "C"
