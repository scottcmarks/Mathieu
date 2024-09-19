/*
 *  Constants.h
 *  SporadicM12
 *
 *  Created by Scott Marks on 12/19/08.
 *  Copyright © 2008, 2023 Magnolia Heights Research and Development. All rights reserved.
 *
 */

// Use this for making simplified screens for icon preparation
#if ! defined( ICONIC_PICTURE_ONLY )
    #define ICONIC_PICTURE_ONLY 0
#endif

// Reward levels -- TODO: M12/M24 specific?
#define FIREWORKS_THRESHOLD 15
#define APPLAUSE_THRESHOLD  20

// Web palette colors -- see e.g.  http://www.visibone.com/colorlab/big.html

#define WHITE              { 0xFF, 0xFF, 0xFF }
#define YELLOW             { 0xFF, 0xFF, 0x00 }
#define LIGHT_HARD_ORANGE  { 0xFF, 0x99, 0x33 }
#define PALE_DULL_PINK     { 0xFF, 0x99, 0xCC }
#define RED                { 0xFF, 0x00, 0x00 }
#define MAGENTA            { 0xFF, 0x00, 0xFF }
#define DARK_HARD_ORANGE   { 0xCC, 0x66, 0x00 }
#define LIGHT_HARD_VIOLET  { 0xBB, 0x55, 0xFF }
#define LIGHT_AZURE_BLUE   { 0x77, 0xAA, 0xFF }
#define LIGHT_BLUE_AZURE   { 0x44, 0x77, 0xFF }
#define DARK_HARD_CYAN     { 0x00, 0xCC, 0xCC }
#define DARK_HARD_GREEN    { 0x00, 0xCC, 0x00 }


#define MAX_ANIMATION_DURATION_FACTOR 3.0
#define MACROPRESSTIME 1.5  // seconds

#define INSTANTANEOUS 0.0
#define SMALL_MOVE_DURATION 0.1
#define LARGE_MOVE_DURATION 1.0

#define kAccelerometerFrequency			25 //Hz
#define kFilteringFactor				0.1
#define kMinEraseInterval				0.5
#define kEraseAccelerationThreshold		3.0

#define ballFontSize      ( _ballRadius + 2.0 )
#define tagFontSize       round( ballFontSize * 0.73 )
#define historyFontSize       13.0
#define movesFontSize         13.0
#if FREE
#define fullAppNameString applicationName @" Free"
#else
#define fullAppNameString applicationName
#endif
#define fullAppName NSLocalizedString(fullAppNameString, @"App Name")

// Apple user interface recommendation
#define TOUCH_SPOT_SIZE       44.0

#define lastComboButton       'E'
#if FREE
    #define lastComboButtonForThisVersion 'B'
#else
    #define lastComboButtonForThisVersion 'E'
#endif

#undef shortLSRNames

