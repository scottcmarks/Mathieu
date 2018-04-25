/*
 *  view.cc
 *  SporadicM12
 *
 *  Created by Scott Marks on 10/19/08.
 *  Copyright © 2008, 2018 Magnolia Heights Research and Development. All rights reserved.
 *
 */
#include "view.h"

#ifdef _MSC_VER
#define _USE_MATH_DEFINES
#endif
#include <math.h>
#include <sstream>

using namespace std;

const double delta_theta= (2 * M_PI)/(nBalls -1);

#define Ball0RadiusOffset (2.5 * ballRadius)
void CalculateBallCoordinates( const point & circleCenter,
                              const double circleRadius,
                              const double ballRadius,
                              point ballCoordinates[ nBalls ])
{
    ballCoordinates[ 0 ] = circleCenter - point(                0, circleRadius + Ball0RadiusOffset );
    for (Index i = 1; i < nBalls; i++)
    {
        double theta = delta_theta * ( i - 1 ) - M_PI_2 ;
        ballCoordinates[ i ] = point( polar( circleRadius            , theta ) ) + circleCenter;
    }
}

#define TagOffset (1.5 * ballRadius)
void CalculateTagCoordinates( const point & circleCenter,
                              const double circleRadius,
                              const double ballRadius,
                              point tagCoordinates[ nBalls ] )
{
#if defined( TOP_TAG_ON_THE_LEFT )
    tagCoordinates[ 0 ]  = circleCenter - point( +TagOffset, circleRadius + Ball0RadiusOffset );
#elif defined( TOP_TAG_ON_THE_RIGHT )
    tagCoordinates[ 0 ]  = circleCenter - point( -TagOffset, circleRadius + Ball0RadiusOffset );
#else /* TOP_TAG_ON_THE_TOP */
    tagCoordinates[ 0 ]  = circleCenter - point(          0, circleRadius + Ball0RadiusOffset + TagOffset) ;
#endif
    for (Index i = 1; i < nBalls; i++)
    {
        double theta = delta_theta * ( i - 1 ) - M_PI_2 ;
        tagCoordinates[ i ]  = point( polar( circleRadius - TagOffset, theta ) ) + circleCenter;
    }
}

bool FindBallWedge( const point probe,
                    const point circleCenter, const double innerCircleRadius, const double outerCircleRadius,
                    Index & wedge, double & theta )
{
    polar p = polar( probe - circleCenter ).rotate( M_PI_2 );
    if ( ! ( innerCircleRadius <= p.rho  &&  p.rho <= outerCircleRadius ) )
        return false;
    theta = p.theta;
    p = p.rotate( delta_theta / 2.0 );
    const double adjustedTheta = p.theta < 0.0 ? p.theta + 2 * M_PI : p.theta ;
    wedge = (Index)( 1 + floor( adjustedTheta / delta_theta ) );
    return true;
}

// TODO: Localization
static const char left_tag ='L';
static const char swap_tag ='S';
static const char right_tag='R';
static const wchar_t superscripts[]=L"⁰¹²³⁴⁵⁶⁷⁸⁹";

template< typename ostream_type, typename char_type >
static ostream_type & insert_count( ostream_type & os, char_type tag, int count )
{
  os << tag;
    if ( 1 < count ) {
        if (count < 10 ) {
            os << superscripts[count];
        } else {
            os << superscripts[count / 10] << superscripts[count % 10];
        }
    }
  return os;
}

static ostream & insert_left( ostream & os, int count ){
  return insert_count( os, left_tag, count );
}

static ostream & insert_swap( ostream & os ){
  return os << swap_tag;
}

static ostream & insert_right( ostream & os, int count ){
  return insert_count( os, right_tag, count );
}

static ostream & insert_macro( ostream & os, HistoryElement e ){
  return os << e;
}

static ostream & insert_macro_inverted( ostream & os, HistoryElement e ){
  return os << '~' << e ;
}

#define as(type,object)(*dynamic_cast<type *>(&(object)))
string str( const History & h ){
  stringstream rss(stringstream::in | stringstream::out);
  h.insert( as(ostream,rss), insert_left, insert_swap, insert_right, insert_macro, insert_macro_inverted );
  string rsstr;
  rss >> rsstr;
  return rsstr;
}



static const wchar_t superscriptMinusOne[ ] = { superscriptMinus, superscriptOne, 0 };
const std::wstring superscriptMinusOneString( superscriptMinusOne );

static wostream & insert_left( wostream & os, int count ){
  return insert_count( os, os.widen( left_tag ), count );
}

static wostream & insert_swap( wostream & os ){
  return os << os.widen( swap_tag );
}

static wostream & insert_right( wostream & os, int count ){
  return insert_count( os, os.widen( right_tag ), count );
}

static wostream & insert_macro( wostream & os, HistoryElement e ){
  return os << os.widen( e );
}

static wostream & insert_macro_inverted( wostream & os, HistoryElement e ){
  return os << os.widen( e ) << superscriptMinusOneString;
}


wstring wstr( const History & h )
{
    wstringstream rss(wstringstream::in | wstringstream::out);
    h.insert( as(wostream,rss), insert_left, insert_swap, insert_right, insert_macro, insert_macro_inverted );
    wstring rsstr;
    rss >> rsstr;
    return rsstr;
}

string cycles_str( const MathieuPermutation & p )
{
    stringstream rss(stringstream::in | stringstream::out);
    p.insert_as_cycles( as(ostream,rss) );
    string rsstr;
    for ( char c = (char)rss.get( ) ; !rss.eof( ) ; c = (char)rss.get( ) )
        rsstr += c ;
    return rsstr;
}

wstring cycles_wstr( const MathieuPermutation & p )
{
    wstringstream rss(wstringstream::in | wstringstream::out);
    p.insert_as_cycles( as(wostream,rss) );
    wstring rsstr;
    for ( wchar_t wc = (wchar_t)rss.get( ) ; !rss.eof( ) ; wc = (wchar_t)rss.get( ) )
        rsstr += wc ;
    return rsstr;
}

