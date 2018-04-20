/*
 *  m24.cc
 *  SporadicM24
 *
 *  Created by Scott Marks on 10/15/08.
 *  Copyright © 2008, 2018 Magnolia Heights Research and Development. All rights reserved.
 *
 */


#include "m24.h"

using namespace std;

// Pick a nice default swap index from 0..0   // Haven't generated M24 permutations
#define INITIAL_SWAP_PERMUTATION_INDEX 0


// Below are the generators of M24, "swap" and "right"
// swap is a permutation composed of (nBalls/2) 2-cycles
// right is a permutation composed of (0) with a (nBalls-1)-cycle.

//                                            0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23
//

MathieuPermutation::swap_table_entry MathieuPermutation::swaps[ ] =
{
                                      { 0, {  1,  0, 23,  4,  3, 22, 11,  8,  7, 10,  9,  6, 21, 14, 13, 20, 17, 16, 19, 18, 15, 12,  5,  2 } }
};
MathieuPermutation::PermArray const & swap_perm = MathieuPermutation::swaps[ INITIAL_SWAP_PERMUTATION_INDEX ].swap; 
MathieuPermutation MathieuPermutation::swapPermutation( swap_perm );

int MathieuPermutation::swapPermutationIndex = INITIAL_SWAP_PERMUTATION_INDEX;

MathieuPermutation::PermArray right_perm = {  0, 23,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 };
MathieuPermutation MathieuPermutation::rightPermutation( right_perm );
