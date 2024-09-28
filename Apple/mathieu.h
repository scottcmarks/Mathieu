#if !defined(__MATHIEU_H_INCLUDED__)
#define __MATHIEU_H_INCLUDED__
/*
 *  mathieu.h
 *  Mathieu
 *
 *  Created by Scott Marks on 03/04/09.
 *  Copyright © 2009, 2023 Magnolia Heights Research and Development. All rights reserved.
 *
 */

#if MATHIEU_GROUP_PERMUTATION_SIZE==12

    #include "m12.h"
    #include "Constants.h"
    #include "M12Constants.h"

#elif MATHIEU_GROUP_PERMUTATION_SIZE==24

    #include "m24.h"
    #include "Constants.h"
    #include "M24Constants.h"

#else

    #error MATHIEU_GROUP_PERMUTATION_SIZE not defined

#endif  /* MATHIEU_GROUP_PERMUTATION_SIZE  */

#endif /* !defined(__MATHIEU_H_INCLUDED__) */
