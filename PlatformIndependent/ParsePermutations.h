#if !defined( __PARSE_PERMUTATIONS_H_INCLUDED__ )
#define __PARSE_PERMUTATIONS_H_INCLUDED__

#include <string>

#include "mathieu.h"

bool parse_permutation_number( std::string s, Rank & n_permutation, const Rank nPermutations );

bool parse_permutation_items( const std::vector< std::string > & items, Permutation::PermArray & permutation );

#endif /* !defined( __PARSE_PERMUTATIONS_H_INCLUDED__ ) */
