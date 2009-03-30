/*
 *  view.h
 *  Mathieu
 *
 *  Created by Scott Marks on 03/04/09.
 *  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
 *
 */

#include "mathieu.h"
#include "point.h"
#include <string>
typedef MPermutationWithHistory::HistoryElement HistoryElement;
typedef MPermutationWithHistory::History History;

// Unicode constants for superscript -1
const wchar_t superscriptMinus = 0x207B;
const wchar_t superscriptOne   = 0x00B9;
extern const std::wstring superscriptMinusOneString;

extern void CalculateBallCoordinates( const point & circleCenter,
                                      const double circleRadius,
                                      const double ballRadius,
                                      point ballCoordinates[ nBalls ],
                                      point tagCoordinates[ nBalls ] );

extern bool FindBallWedge( const point probe,
                           const point circleCenter, const double innerCircleRadius, const double outerCircleRadius,
                           Index & wedge, double & theta );

extern std::string str( const History & h );
extern std::wstring wstr( const History & h );
extern std::string cycles_str( const MPermutation & p );
extern std::wstring cycles_wstr( const MPermutation & p );