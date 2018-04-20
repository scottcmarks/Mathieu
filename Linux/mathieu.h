#if !defined(__MATHIEU_H_INCLUDED__)
#define __MATHIEU_H_INCLUDED__
/*
 *  mathieu.h
 *  Mathieu
 *
 *  Created by Scott Marks on 03/04/09.
 *  Copyright © 2009, 2018 Magnolia Heights Research and Development. All rights reserved.
 *
 */

#if MATHIEU_GROUP_PERMUTATION_SIZE==12
    #import "m12.h"
#elif MATHIEU_GROUP_PERMUTATION_SIZE==24
    #import "m24.h"
#else
    #error MATHIEU_GROUP_PERMUTATION_SIZE not defined
#endif  /* MATHIEU_GROUP_PERMUTATION_SIZE  */

#endif /* !defined(__MATHIEU_H_INCLUDED__) */
