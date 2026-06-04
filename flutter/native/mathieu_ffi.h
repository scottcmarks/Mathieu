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

#ifdef __cplusplus
}
#endif

#endif // MATHIEU_FFI_H
