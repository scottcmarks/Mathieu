#if !defined(__M24CONSTANTS_H_INCLUDED__)
#define __M24CONSTANTS_H_INCLUDED__

/*
 *  M24Constants.h
 *  SporadicM24
 *
 *  Created by Scott Marks on 3/10/09.
 *  Copyright 2009 Magnolia Heights R&D. All rights reserved.
 *
 */


// These are fiddly program parameters.
#define MBallRadiusRatio   0.09375
#define ballFontSize      (_ballRadius + 2 )
#define tagFontSize       round( ballFontSize * 0.75 )
#define historyFontSize       13.0
#define appName               @"M24"
#if LITE
#define fullAppName appName @" Lite"
#else
#define fullAppName appName
#endif

#endif /* !defined(__M24CONSTANTS_H_INCLUDED__) */
