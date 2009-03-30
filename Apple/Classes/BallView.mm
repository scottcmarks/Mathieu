//
//  BallView.m
//  SporadicM12
//
//  Created by Jackie Marks on 10/21/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "BallView.h"
#import "mathieu.h"
#import "Constants.h"
#import "Utilities.h"

@implementation BallView

typedef struct { unsigned char r; unsigned char g; unsigned char b; } BallColor;

static BallColor colors[ ] = {
     WHITE             ,
     PALE_DULL_PINK    ,
     LIGHT_HARD_ORANGE ,
     YELLOW            ,
     DARK_HARD_GREEN   ,
     MAGENTA           ,
     LIGHT_AZURE_BLUE  ,
     LIGHT_BLUE_AZURE  ,
     DARK_HARD_ORANGE  ,
     RED               ,
     LIGHT_HARD_VIOLET ,
     DARK_HARD_CYAN    ,
};

static BallColor ballColors[ nBalls ];

+ ( void ) initialize 
{
    const MPermutation & swap = MPermutation::swapPermutation;
    int lastColorUsed = -1;
    bool colorIsSet[ nBalls ];
    forAllBalls( i ) colorIsSet[ i ] = false;
    forAllBalls( i )
        if ( ! colorIsSet[ i ] )
        {
            lastColorUsed ++;
            ballColors[ i ] = ballColors[ swap[ i ] ] = colors[ lastColorUsed ];
            colorIsSet[ i ] = colorIsSet[ swap[ i ] ] = true;
        }
}

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
