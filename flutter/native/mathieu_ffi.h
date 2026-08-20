//
//  mathieu_ffi.h
//  C ABI for the Mathieu "M12" engine. Used by Dart FFI (Flutter) and by the
//  watchOS app's Swift bridging header.
//
#ifndef MATHIEU_FFI_H
#define MATHIEU_FFI_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// lifecycle
void* mathieu_new(void);
void  mathieu_free(void* h);

// constants
int mathieu_num_balls(void);
int mathieu_num_swaps(void);

// moves
void mathieu_reset(void* h);
void mathieu_left(void* h, int count);
void mathieu_right(void* h, int count);
void mathieu_swap(void* h);
void mathieu_random(void* h);
int  mathieu_undo(void* h, int move);   // move!=0 = full move, 0 = single step
void mathieu_revert(void* h);           // back to the scramble, keeping macros
int  mathieu_moves(void* h);
int  mathieu_steps(void* h);

// state
void mathieu_get_arrangement(void* h, int* out);   // out[i] = ball value at slot i
int  mathieu_history_length(void* h);
int  mathieu_history_is_empty(void* h);
int  mathieu_is_solved(void* h);
void mathieu_history_str(void* h, char* out, int cap);

// swap-permutation selection (static, shared)
void mathieu_set_swap_index(int i);
int  mathieu_get_swap_index(void);
int  mathieu_swap_difficulty(int i);
void mathieu_get_swap_permutation(int* out);
void mathieu_get_swap_permutation_at(int i, int* out);

// macros ("combos" A..E, codes 65..69), stored per-game
int  mathieu_macro_defined(void* h, int c);
int  mathieu_any_macro_defined(void* h);
void mathieu_set_macro(void* h, int c);
void mathieu_erase_macro(void* h, int c);
void mathieu_erase_all_macros(void* h);
void mathieu_run_macro(void* h, int c, int inverted);
int  mathieu_history_is_single_macro(void* h, int c);

// --- macro introspection (added for the in-app tutorial) ---
// Everything below is APPEND-ONLY: the watchOS bridging header imports this
// file, and the watch app binds only the entry points above.

// out[i] = the image of seat i under macro c's own permutation, i.e. the group
// element the macro applies, with the position it was recorded from divided
// out. Returns 0 (leaving out untouched) if c is not defined.
int  mathieu_macro_permutation(void* h, int c, int* out);

// Macro c's word in the same notation as mathieu_history_str ("R S R S ").
// Empty if c is not defined.
void mathieu_macro_history_str(void* h, int c, char* out, int cap);

// Define macro c on handle h as the game currently held by handle src — so a
// caller can replay an arbitrary word on a scratch handle and bind the result
// without disturbing h's own history. (Avoids putting a word parser in C.)
void mathieu_set_macro_from(void* h, int c, void* src);

// The position the current solve started from (identity after reset, the
// scramble after random). This is what mathieu_set_macro divides out.
void mathieu_get_start(void* h, int* out);

// Put the board at a chosen position with an empty history — random() to a
// position you picked, so a lesson can say "you are nine moves from home" and
// be exactly right. Rejects anything that is not a permutation of 0..n-1 and
// returns 0; returns 1 on success. Macro definitions are kept.
int mathieu_set_position(void* h, const int* perm);

#ifdef __cplusplus
}
#endif

#endif // MATHIEU_FFI_H
