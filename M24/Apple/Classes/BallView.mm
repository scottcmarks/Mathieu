//
//  BallView.m
//  SporadicM24
//
//  Created by Jackie Marks on 10/21/08.
//  Copyright 2008 Magnolia Heights Research and Development.. All rights reserved.
//

#import "BallView.h"
#import "m24.h"
#import "Constants.h"
#import "Utilities.h"

@implementation BallView

@synthesize R;
@synthesize G;
@synthesize B;



typedef struct { unsigned char r; unsigned char g; unsigned char b; } BallColor;

BallColor ballColors[ ] = {
WHITE             ,  //  0 - White for 0 and 1
WHITE             ,  //  1 - White for 0 and 1
PALE_DULL_PINK    ,  //  2 - Pink for 2 and 23
LIGHT_HARD_ORANGE ,  //  3 - Orange for 3 and 4
LIGHT_HARD_ORANGE ,  //  4 - Orange for 3 and 4
YELLOW            ,  //  5 - Yellow for 5 and 22
DARK_HARD_GREEN   ,  //  6 - Green for 6 and 11
MAGENTA           ,  //  7 - Magenta for 7 and 8
MAGENTA           ,  //  8 - Magenta for 7 and 8
LIGHT_AZURE_BLUE  ,  //  9 - Light Blue for 9 and 10
LIGHT_AZURE_BLUE  ,  // 10 - Light Blue for 9 and 10
DARK_HARD_GREEN   ,  // 11 - Green for 6 and 11
LIGHT_BLUE_AZURE  ,  // 12 - Blue for 12 and 21
DARK_HARD_ORANGE  ,  // 13 - Dark Orange for 13 and 14
DARK_HARD_ORANGE  ,  // 14 - Dark Orange for 13 and 14
RED               ,  // 15 - Red for 15 and 20
LIGHT_HARD_VIOLET ,  // 16 - Violet for 16 and 17
LIGHT_HARD_VIOLET ,  // 17 - Violet for 16 and 17
DARK_HARD_CYAN    ,  // 18 - Dark Cyan for 18 and 19
DARK_HARD_CYAN    ,  // 19 - Dark Cyan for 18 and 19
RED               ,  // 20 - Red for 15 and 20
LIGHT_BLUE_AZURE  ,  // 21 - Blue for 12 and 21
YELLOW            ,  // 22 - Yellow for 5 and 22
PALE_DULL_PINK    ,  // 23 - Pink for 2 and 23
};

- (id)initWithFrame:(CGRect)frame ballNumber:(int)i {
    if ( self = [super initWithFrame:frame] ) {
        R = ballColors[i].r/255.0;
        G = ballColors[i].g/255.0;
        B = ballColors[i].b/255.0;
    }
    self.backgroundColor = [UIColor clearColor];
    return self;
}

- (void)drawRect:(CGRect)rect {

    // Make the gradient
    const int nLocations = 3;

    CGFloat colors[ 4 * nLocations ] =
    {
        0.6*R, 0.6*G, 0.6*B, 0.0,  // Start color
        0.6*R, 0.6*G, 0.6*B, 1.0,  // Middle color
        1.0*R, 1.0*G, 1.0*B, 1.0,  // End color
    };
    CGFloat locations[ nLocations ] = { 0.0, 0.05, 1.0 };

    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents( rgb, colors, locations, nLocations );
    CGColorSpaceRelease(rgb);

    // Draw a radial gradient to make the 2D image of a sphere cap lit from above
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextClearRect(ctx, rect);
    CGContextDrawRadialGradient (ctx, gradient,
                                 CGPointMake( CGRectGetMidX( rect ), CGRectGetMidY( rect )  ),  // start point
                                 CGRectGetWidth( rect )/2,                                      // start radius
                                 CGPointMake( CGRectGetMidX( rect ), CGRectGetMidY( rect )/4 ), // end point
                                 0.0,                                                           // end radius
                                 kCGGradientDrawsAfterEndLocation);                             // no flags

    CGGradientRelease( gradient );
}


@end
