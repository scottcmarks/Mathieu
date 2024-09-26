//
//  BallView.m
//  SporadicM12
//
//  Created by Scott Marks on 10/21/08.
//  Copyright © 2008, 2023 Magnolia Heights Research and Development. All rights reserved.
//

#import "BallView.h"
#import "Utilities.h"

@implementation BallView

typedef struct { unsigned char r; unsigned char g; unsigned char b; } BallColor;

static BallColor colors[ ] = {
    BALL_COLORS    // defined in MxxConstants.h
};

static BallColor ballColors[ nBalls ];

+ ( void ) setColorsForSwapPermutation: ( const MathieuPermutation & ) swap
{
    int nextColorToUse = 0;
    bool colorIsSet[ nBalls ] = {false};
    forAllBalls( i ) {
        if ( ! colorIsSet[ i ] )
        {
            BallColor color = colors[ nextColorToUse++ ];
            ballColors[ i ] = ballColors[ swap[ i ] ] = color;
            colorIsSet[ i ] = colorIsSet[ swap[ i ] ] = true;
        }
    }
}

+ ( void ) setColorsForCurrentSwapPermutation {
    [ self setColorsForSwapPermutation: MathieuPermutation::swapPermutation] ;
}


- (id)initWithFrame:(CGRect)frame ballNumber:( int ) ballNumber
{
    if ( self = [super initWithFrame:CGRect_to_NSRect(frame)] )
    {
        _ballNumber = ballNumber;
#if TARGET_IOS
        self.backgroundColor = [UIColor clearColor];
#endif /* TARGET_IOS */
    }
    return self;
}

+ ( BallView * ) ballViewWithFrame: ( CGRect ) frame ballNumber:( int ) ballNumber
{
    return [ [ [ self alloc ] initWithFrame:frame ballNumber: ballNumber ] autorelease];
}


- (void)drawRect:(CGRect)rect {

    const float R = ballColors[ _ballNumber ].r / 255.0;
    const float G = ballColors[ _ballNumber ].g / 255.0;
    const float B = ballColors[ _ballNumber ].b / 255.0;

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

    CGContextRef ctx =
#if TARGET_IOS
                       UIGraphicsGetCurrentContext( );
#elif TARGET_MACOS
                       ( CGContextRef ) [ [ NSGraphicsContext currentContext ] graphicsPort ];
#else
#error Don't know this platform!
#endif

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
