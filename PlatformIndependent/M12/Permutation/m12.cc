 /*
 *  m12.cc
 *  SporadicM12
 *
 *  Created by Scott Marks on 10/15/08.
 *  Copyright © 2008, 2023 Magnolia Heights Research and Development. All rights reserved.
 *
 */


#include "m12.h"

// Pick a nice default swap index from 0..340
#define INITIAL_SWAP_PERMUTATION_INDEX 1   

// Below are the original SciAm M12 generators.
// swap was called "Inverse", and right was called "Merge"
// MathieuPermutation::PermArray swap_perm  = { 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1,  0 } ;
// MathieuPermutation::PermArray right_perm = {  0, 11,  1, 10,  2,  9,  3,  8,  4,  7,  5,  6 } ;
// These underwent renaming to make M12 generators  0->0 1->1 2->3 3->5 4->7 5->9 6->10 7->8 8->6 9->4 10->2 11->11

// Below are the generators of M12, "swap" and "right"
// swap is a permutation composed of (nBalls/2) 2-cycles
// right is a permutation composed of (0) with a (nBalls-1)-cycle.

// Include all 341 permutations that are six 2-cycles and still generate the whole group
#include "swaps.inc"

// Use the second one as it makes a simple 4-preserving move

MathieuPermutation::PermArray const & swap_perm = MathieuPermutation::swaps[ INITIAL_SWAP_PERMUTATION_INDEX ].swap; 
MathieuPermutation MathieuPermutation::swapPermutation( swap_perm );
int MathieuPermutation::swapPermutationIndex = INITIAL_SWAP_PERMUTATION_INDEX;

MathieuPermutation::PermArray right_perm= {  0, 11,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10 };
MathieuPermutation MathieuPermutation::rightPermutation( right_perm );



