-----------------------------------------------------------------------
--                          G N A T C O L L                          --
--                                                                   --
--                 Copyright (C) 2010, AdaCore                       --
--                                                                   --
-- GPS is free  software;  you can redistribute it and/or modify  it --
-- under the terms of the GNU General Public License as published by --
-- the Free Software Foundation; either version 2 of the License, or --
-- (at your option) any later version.                               --
--                                                                   --
-- This program is  distributed in the hope that it will be  useful, --
-- but  WITHOUT ANY WARRANTY;  without even the  implied warranty of --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU --
-- General Public License for more details. You should have received --
-- a copy of the GNU General Public License along with this program; --
-- if not,  write to the  Free Software Foundation, Inc.,  59 Temple --
-- Place - Suite 330, Boston, MA 02111-1307, USA.                    --
-----------------------------------------------------------------------

--  A set of planar geometric utilites (intersections of segments, etc).

with Ada.Numerics.Generic_Elementary_Functions;

generic
   type Coordinate is digits <>;
   --  The type used to represent coordinates and distances

package GNATCOLL.Geometry is

   package Coordinate_Elementary_Functions is new
     Ada.Numerics.Generic_Elementary_Functions (Coordinate);

   type Point is record
      X, Y : Coordinate;
   end record;
   --  General representation for a point in 2D

   No_Point        : constant Point;
   --  Constant used to indicate that the point doesn't exist (no intersection
   --  for instance)

   Infinity_Points : constant Point;
   --  Constant used to indicate that an infinity number of points would match,
   --  for instance in the case of the intersection of coincident lines

   type Polygon   is array (Positive range <>) of Point;
   type Triangle  is new Polygon (1 .. 3);
   type Segment   is array (1 .. 2) of Point;
   type Vector    is new Point;

   type Rectangle is new Polygon (1 .. 2);
   --  A rectangle has sides parallel to the two axis of the space coordinates.
   --  It is defined by its top-left and bottom-right corners. If you need a
   --  more general definition of a rectangle, use the generic algorithms on
   --  polygons.

   type Line is private;

   type Circle is record
      Center : Point;
      Radius : Coordinate;
   end record;
   No_Circle : constant Circle;

   function To_Vector (S : Segment) return Vector;
   --  Return the vector that indicates the direction and magnitude of the
   --  segment.

   function To_Line (P1, P2 : Point) return Line;
   function To_Line (Seg : Segment) return Line;
   --  Return the line going through the two points, or overlapping the
   --  segment.

   function To_Circle (P1, P2, P3 : Point) return Circle;
   --  Return the circle that passes through the 3 points. If the 3 points are
   --  colinear, No_Circle is returned.

   function "-" (P2, P1 : Point) return Vector;
   --  Return the vector to go from P1 to P2.

   function Dot (Vector1, Vector2 : Vector) return Coordinate;
   --  Return the dot product of Vector1 and Vector2. Mathematically, this is
   --  also the value of |Vector1| * |Vector2| * cos (alpha), where alpha is
   --  the angle between the two vectors. When Dot is 0, the two vectors are
   --  orthogonal or null.

   function Cross (Vector1, Vector2 : Vector) return Coordinate;
   --  Return the magnitude of the cross-product of the two vectors.
   --  Technically, this is also a vector, but since we are in 2D, this is
   --  represented as a scalar.
   --
   --  In 2D, this is also the value of  |Vector1| * |Vector2| * sin (alpha).
   --  This is positive if Vector1 is less than 180 degrees clockwise from B.
   --
   --  Last, in 2D the cross product is also the area of the parallelogram with
   --  two of its side formed by Vector1 and Vector2.
   --         ----A---
   --         \       \
   --          B       |
   --           \       \
   --            ---------

   function Length (Vect : Vector) return Coordinate;
   --  Return the magnitude of the vector

   function Bisector (S : Segment) return Line;
   pragma Inline (Bisector);
   --  Return the bisector to S, i.e. the line that is perpendicular to S and
   --  goes through its middle.

   function Intersection (S1, S2 : Segment) return Point;
   function Intersection (L1, L2 : Line)    return Point;
   --  Return the intersection of the two parameters. The result is either a
   --  simple point, or No_Point when they don't intersect, or
   --  Infinity_Points when the two parameters intersect on an infinity of
   --  points.

   function Intersect (C1, C2 : Circle)      return Boolean;
   function Intersect (T1, T2 : Triangle)    return Boolean;
   function Intersect (L : Line; C : Circle) return Boolean;
   function Intersect (R1, R2 : Rectangle)   return Boolean;
   --  Whether the two parameters intersect

   function Inside (P : Point; S    : Segment)  return Boolean;
   function Inside (P : Point; L    : Line)     return Boolean;
   function Inside (P : Point; T    : Triangle) return Boolean;
   function Inside (P : Point; Poly : Polygon)  return Boolean;
   --  True if P is on the segment or line

   function Distance (From : Point; To : Point)   return Coordinate;
   function Distance (From : Point; To : Segment) return Coordinate;
   function Distance (From : Point; To : Line)    return Coordinate;
   function Distance (From : Point; To : Polygon) return Coordinate;
   --  Return the distance between P and the second parameter. This is not
   --  efficient for comparing distances, since this involves a square root
   --  computation (see Unnormalized_Distance)

   function Centroid (Self : Polygon) return Point;
   --  Return the centroid of the polygon (aka center of gravity).

   function Area (Self : Triangle) return Coordinate;
   function Area (Self : Polygon)  return Coordinate;
   --  Return the area of the (possibly non-convex) polygon. For the triangle,
   --  the area will be negative if the vertices are oriented clockwise

   function Same_Side (P1, P2 : Point; As : Segment) return Boolean;
   function Same_Side (P1, P2 : Point; As : Line)    return Boolean;
   --  Whether the two points lay on the same side of the line overlapping
   --  the segment. It is slightly faster to use the Segment version

private
   type Line is record
      A, B, C : Coordinate;
   end record;
   --  Representation for a line, through its equation, that
   --  is:   Ax + By = C. See functions To_Line below if you define a line
   --  by a set of points.

   No_Point  : constant Point  := (Coordinate'First, Coordinate'First);
   No_Circle : constant Circle := (No_Point, Coordinate'First);
   Infinity_Points : constant Point :=
     (Coordinate'Last, Coordinate'Last);
end GNATCOLL.Geometry;