/*
 *  view.h
 *  SporadicM12
 *
 *  Created by Jackie Marks on 10/19/08.
 *  Copyright 2008 Magnolia Heights Research and Development.. All rights reserved.
 *
 */

#include "m12.h"
#include "point.h"
#include <string>
typedef M12PermutationWithHistory::HistoryElement HistoryElement;
typedef M12PermutationWithHistory::History History;

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
