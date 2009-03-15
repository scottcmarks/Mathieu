#if !defined(__MATHIEU_H_INCLUDED__)
#define __MATHIEU_H_INCLUDED__
/*
 *  mathieu.h
 *  Mathieu
 *
 *  Created by Scott Marks on 03/04/09.
 *  Copyright 2009 Magnolia Heights Research and Development.  All rights reserved.
 *
 */

#if MATHIEU_GROUP_PERMUTATION_SIZE==12

#import "m12.h"
#import "Constants.h"
#import "M12Constants.h"
typedef M12Permutation MPermutation;
typedef M12PermutationWithHistory MPermutationWithHistory;

#elif MATHIEU_GROUP_PERMUTATION_SIZE==24

#import "m24.h"
#import "Constants.h"
#import "M24Constants.h"
typedef M24Permutation MPermutation;
typedef M24PermutationWithHistory MPermutationWithHistory;

#else

#error MATHIEU_GROUP_PERMUTATION_SIZE not defined

#endif  /* nBalls  */

#endif /* !defined(__MATHIEU_H_INCLUDED__) */
