#if !defined(__M12CONSTANTS_H_INCLUDED__)
#define __M12CONSTANTS_H_INCLUDED__

/*
 *  M12Constants.h
 *  SporadicM12
 *
 *  Created by Scott Marks on 3/10/09.
 *  Copyright 2009 Magnolia Heights R&D. All rights reserved.
 *
 */


// These are fiddly program parameters.
#define MBallRadiusRatio  0.137500
#define ballFontSize      ( _ballRadius + 2.0 )
#define tagFontSize       round( ballFontSize * 0.73 )
#define historyFontSize       13.0
#define appName               @"M12"
#if LITE
#define fullAppName appName @" Lite"
#else
#define fullAppName appName
#endif

#endif /* !defined(__M12CONSTANTS_H_INCLUDED__) */
