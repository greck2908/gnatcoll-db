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

--  Algorithms in this package are adapted from the following books and
--  articles:
--
--   [GGII]   Graphic Gems II
--              http://www1.acm.org/pubs/tog/GraphicsGems/gemsii
--   [GGIV]   Graphic Gems IV
--              http://www1.acm.org/pubs/tog/GraphicsGems/gemsiv
--   [CGA]    comp.lang.graphics
--   [TRI]    http://www.acm.org/jgt/papers/GuigueDevillers03/
--              triangle_triangle_intersection.html
--   [PTTRI]  http://www.blackpawn.com/texts/pointinpoly/default.html
--   [SEGSEG] http://astronomy.swin.edu.au/~pbourke/geometry/lineline2d/
--   [GEO]    http://geometryalgorithms.com/Archive/algorithm_Zero4

package body GNATCOLL.Geometry is

   use Coordinate_Elementary_Functions;

   function Orient (P, Q, R : Point) return Coordinate;  --  From [TRI]
   pragma Inline (Orient);

   function Tri_Intersection
     (P1, Q1, R1, P2, Q2, R2 : Point) return Boolean;  --  From [TRI]
   function Intersection_Test_Edge
     (P1, Q1, R1, P2, Q2, R2 : Point) return Boolean;  --  From [TRI]
   pragma Inline (Intersection_Test_Edge);
   function Intersection_Test_Vertex
     (P1, Q1, R1, P2, Q2, R2 : Point) return Boolean;  --  From [TRI]
   pragma Inline (Intersection_Test_Vertex);
   --  Return whether the two triangles intersect. Points need to be sorted

   Zero : constant Coordinate := Coordinate (0);
   Two  : constant Coordinate := Coordinate (2);
   --  ??? We should not compare with Zero. In the case of float coordinates,
   --  we should compare if less than a small delta.

   -------------
   -- To_Line --
   -------------

   function To_Line (P1, P2 : Point) return Line is
      A : constant Coordinate := P2.Y - P1.Y;
      B : constant Coordinate := P2.X - P1.X;
   begin
      return (A => A,
              B => B,
              C => A * P1.X + B * P1.Y);
   end To_Line;

   -------------
   -- To_Line --
   -------------

   function To_Line (Seg : Segment) return Line is
   begin
      return To_Line (Seg (1), Seg (2));
   end To_Line;

   --------------
   -- Bisector --
   --------------

   function Bisector (S : Segment) return Line is
      L     : constant Line := To_Line (S);
      X_Mid : constant Coordinate := (S (1).X + S (2).X) / Two;
      Y_Mid : constant Coordinate := (S (1).Y + S (2).Y) / Two;
   begin
      return
        (A => -L.B,
         B => L.A,
         C => -L.B * X_Mid + L.A * Y_Mid);
   end Bisector;

   ------------------
   -- Intersection --
   ------------------

   function Intersection (L1, L2 : Line) return Point is
      Det : constant Coordinate := L1.A * L2.B - L2.A * L1.B;
   begin
      if Det = Zero then
         if L1.C = L2.C then
            return Infinity_Points;
         else
            return No_Point;
         end if;
      else
         return (X => (L2.B * L1.C - L1.B * L2.C) / Det,
                 Y => (L1.A * L2.C - L2.A * L1.C) / Det);
      end if;
   end Intersection;

   ------------
   -- Inside --
   ------------

   function Inside (P : Point; L : Line) return Boolean is
   begin
      return L.A * P.X + L.B * P.Y = L.C;
   end Inside;

   ------------
   -- Inside --
   ------------

   function Inside (P : Point; S : Segment) return Boolean is
   begin
      return Inside (P, To_Line (S))
        and then P.X >= Coordinate'Min (S (1).X, S (2).X)
        and then P.X <= Coordinate'Max (S (1).X, S (2).X)
        and then P.Y >= Coordinate'Min (S (1).Y, S (2).Y)
        and then P.Y <= Coordinate'Max (S (1).Y, S (2).Y);
   end Inside;

   ------------------
   -- Intersection --
   ------------------
   --  Algorithm adapted from [GGII - xlines.c]

   function Intersection (S1, S2 : Segment) return Point is
      L1 : constant Line := To_Line (S1);
      R3 : constant Coordinate := L1.A * S2 (1).X + L1.B * S2 (1).Y - L1.C;
      R4 : constant Coordinate := L1.A * S2 (2).X + L1.B * S2 (2).Y - L1.C;
      L2 : constant Line := To_Line (S2);
      R1 : constant Coordinate := L2.A * S1 (1).X + L2.B * S1 (1).Y - L2.C;
      R2 : constant Coordinate := L2.A * S1 (2).X + L2.B * S1 (2).Y - L2.C;

      Denom : Coordinate;

   begin
      --  Check signs of R3 and R4. If both points 3 and 4 lie on same side
      --  of line 1, the line segments do not intersect

      if (R3 > Zero and then R4 > Zero)
         or else (R3 < Zero and then R4 < Zero)
      then
         return No_Point;
      end if;

      --  Check signs of r1 and r2. If both points lie on same side of
      --  second line segment, the line segments do not intersect

      if (R1 > Zero and then R2 > Zero)
         or else (R1 < Zero and then R2 < Zero)
      then
         return No_Point;
      end if;

      --  Line segments intersect, compute intersection point
      Denom := L1.A * L2.B - L2.A * L1.B;
      if Denom = Zero then
         --  colinears
         if Inside (S1 (1), S2)
           or else Inside (S1 (2), S2)
         then
            return Infinity_Points;
         else
            return No_Point;
         end if;
      end if;

      return
        (X => (L2.B * L1.C - L1.B * L2.C) / Denom,
         Y => (L1.A * L2.C - L2.A * L1.C) / Denom);
   end Intersection;

   ---------------
   -- To_Vector --
   ---------------

   function To_Vector (S : Segment) return Vector is
   begin
      return (X => S (2).X - S (1).X,
              Y => S (2).Y - S (1).Y);
   end To_Vector;

   ---------
   -- "-" --
   ---------

   function "-" (P2, P1 : Point) return Vector is
   begin
      return (X => P2.X - P1.X,
              Y => P2.Y - P1.Y);
   end "-";

   ---------
   -- Dot --
   ---------

   function Dot (Vector1, Vector2 : Vector) return Coordinate is
   begin
      return Vector1.X * Vector2.X + Vector1.Y * Vector2.Y;
   end Dot;

   -----------
   -- Cross --
   -----------

   function Cross (Vector1, Vector2 : Vector) return Coordinate is
   begin
      return Vector1.X * Vector2.Y - Vector1.Y * Vector2.X;
   end Cross;

   ------------
   -- Length --
   ------------

   function Length (Vect : Vector) return Coordinate is
   begin
      return Sqrt (Coordinate (Vect.X * Vect.X + Vect.Y * Vect.Y));
   end Length;

   --------------
   -- Distance --
   --------------

   function Distance (From : Point; To : Line) return Coordinate is
   begin
      return abs (To.A * From.X + To.B * From.Y - To.C) /
        Sqrt (To.A * To.A + To.B * To.B);
   end Distance;

   --------------
   -- Distance --
   --------------

   function Distance (From : Point; To : Point) return Coordinate is
      X : constant Coordinate := To.X - From.X;
      Y : constant Coordinate := To.Y - From.Y;
   begin
      return Sqrt (X * X + Y * Y);
   end Distance;

   --------------
   -- Distance --
   --------------

   function Distance (From : Point; To : Segment) return Coordinate is
   begin
      if Dot (From - To (2), To (2) - To (1)) > Zero then
         --  Closest point is Segment (2)
         return Distance (From, To (2));

      elsif Dot (From - To (1), To (1) - To (2)) > Zero then
         --  Closest point is Segment (1)
         return Distance (From, To (1));

      else
         return Distance (From, To_Line (To));
      end if;
   end Distance;

   --------------
   -- Distance --
   --------------

   function Distance (From : Point; To : Polygon) return Coordinate is
      Min : Coordinate := Coordinate'Last;
   begin
      for P in To'First .. To'Last - 1 loop
         Min := Coordinate'Min
            (Min,
             Distance (From, Segment'(To (P), To (P + 1))));
      end loop;
      Min := Coordinate'Min
         (Min,
          Distance (From, Segment'(To (To'First), To (To'Last))));
      return Min;
   end Distance;

   ---------------
   -- Intersect --
   ---------------

   function Intersect (C1, C2 : Circle) return Boolean is
   begin
      return Distance (C1.Center, C2.Center) <= C1.Radius + C2.Radius;
   end Intersect;

   ---------------
   -- Intersect --
   ---------------

   function Intersect (L : Line; C : Circle) return Boolean is
   begin
      return Distance (C.Center, L) <= C.Radius;
   end Intersect;

   ----------
   -- Area --
   ----------

   function Area (Self : Polygon) return Coordinate is
      D : Coordinate := Zero;
   begin
      for P in Self'First + 1 .. Self'Last - 1 loop
         D := D + Cross (Self (P)     - Self (Self'First),
                         Self (P + 1) - Self (Self'First));
      end loop;
      return abs (D / Two);
   end Area;

   ----------
   -- Area --
   ----------

   function Area (Self : Triangle) return Coordinate is
   begin
      return ((Self (2).X - Self (1).X)
              * (Self (3).Y - Self (1).Y)
              - (Self (3).X - Self (1).X)
              * (Self (2).Y - Self (1).Y)) / Two;
   end Area;

   ---------------
   -- To_Circle --
   ---------------

   function To_Circle (P1, P2, P3 : Point) return Circle is
      --  Find the intersection of the two perpendicular bisectors of two of
      --  the segments.
      Bis1 : constant Line := Bisector (Segment'(1 => P1, 2 => P2));
      Bis2 : constant Line := Bisector (Segment'(1 => P2, 2 => P3));
      Center : constant Point := Intersection (Bis1, Bis2);
   begin
      if Center = No_Point or else Center = Infinity_Points then
         return No_Circle;
      else
         return (Center => Center,
                 Radius => Distance (Center, P1));
      end if;
   end To_Circle;

   ------------
   -- Inside --
   ------------

   function Inside (P : Point; Poly : Polygon) return Boolean is
      J : constant Natural := Poly'Last;
      C : Boolean := False;
      Deltay  : Coordinate;
   begin
      --  See http://www.ecse.rpi.edu/Homepages/wrf/Research
      --     /Short_Notes/pnpoly.html
      for S in Poly'Range loop
         Deltay := P.Y - Poly (S).Y;

         --  The divide below is mandatory: if you transform it into a
         --  multiplication on the other side, the sign of the denominator will
         --  flip the inequality, and thus make the code harder.
         if ((Zero <= Deltay and then P.Y < Poly (J).Y)
             or else (Poly (J).Y <= P.Y and then Deltay < Zero))
           and then
             (P.X - Poly (S).X < (Poly (J).X - Poly (S).X) * Deltay
              / (Poly (J).Y - Poly (S).Y))
         then
            C := not C;
         end if;
      end loop;
      return C;
   end Inside;

   --------------
   -- Centroid --
   --------------

   function Centroid (Self : Polygon) return Point is
      X, Y   : Coordinate := Zero;
      Weight : Coordinate := Zero;
      Local  : Coordinate;
   begin
      for P in Self'First + 1 .. Self'Last - 1 loop
         Local := Area
           (Triangle'(Self (Self'First), Self (P), Self (P + 1)));
         Weight := Weight + Local;
         X := X + (Self (Self'First).X + Self (P).X + Self (P + 1).X) / 3.0
           * Local;
         Y := Y + (Self (Self'First).Y + Self (P).Y + Self (P + 1).Y) / 3.0
           * Local;
      end loop;
      return (X => X / Weight, Y => Y / Weight);
   end Centroid;

   ---------------
   -- Same_Side --
   ---------------

   function Same_Side
     (P1, P2 : Point; As : Segment) return Boolean
   is
      --  Direction of cross-product for (L2 - L1) x (P1 - L1)
      Cross1_Z : constant Coordinate :=
        (As (2).X - As (1).X) * (P1.Y - As (1).Y)
      - (As (2).Y - As (1).Y) * (P1.X - As (1).X);

      --  Direction of cross-product for (L2 - L1) x (P2 - L1)
      Cross2_Z : constant Coordinate :=
        (As (2).X - As (1).X) * (P2.Y - As (1).Y)
      - (As (2).Y - As (1).Y) * (P2.X - As (1).X);
   begin
      if Cross1_Z <= Zero then
         return Cross2_Z <= Zero;
      else
         return Cross2_Z > Zero;
      end if;
   end Same_Side;

   ---------------
   -- Same_Side --
   ---------------

   function Same_Side (P1, P2 : Point; As : Line) return Boolean is
      S : Segment;
   begin
      if As.B = Zero then
         --  Horizontal line
         S (1).X := As.C / As.A;
         S (1).Y := Zero;
         S (2).X := S (1).X;
         S (2).Y := Coordinate (100);
      else
         S (1).X := Zero;
         S (1).Y := As.C / As.B;
         S (2).X := Coordinate (100);
         S (2).Y := (As.C - As.A * S (2).X) / As.B;
      end if;

      return Same_Side (P1, P2, S);
   end Same_Side;

   ------------
   -- Inside --
   ------------
   --  Algorithm from [PTTRI]

   function Inside (P : Point; T : Triangle) return Boolean is
   begin
      --  On boundary ?
      if Distance (P, T (1)) = Zero
        or else Distance (P, T (2)) = Zero
        or else Distance (P, T (3)) = Zero
      then
         return True;
      end if;

      return Same_Side (P, T (3), Segment'(T (1), T (2)))
      and then Same_Side (P, T (1), Segment'(T (2), T (3)))
      and then Same_Side (P, T (2), Segment'(T (1), T (3)));
   end Inside;

   ---------------
   -- Orient --
   ---------------

   function Orient (P, Q, R : Point) return Coordinate is
   begin
      return (P.X - R.X) * (Q.Y - R.Y) - (P.Y - R.Y) * (Q.X - R.X);
   end Orient;

   ------------------------------
   -- Intersection_Test_Vertex --
   ------------------------------

   function Intersection_Test_Vertex
     (P1, Q1, R1, P2, Q2, R2 : Point) return Boolean is
   begin
      if Orient (R2, P2, Q1) >= Zero then
         if Orient (R2, Q2, Q1) <= Zero then
            if Orient (P1, P2, Q1) > Zero then
               return Orient (P1, Q2, Q1) <= Zero;
            else
               if Orient (P1, P2, R1) >= Zero then
                  return Orient (Q1, R1, P2) >= Zero;
               else
                  return False;
               end if;
            end if;
         else
            if Orient (P1, Q2, Q1) <= Zero then
               if Orient (R2, Q2, R1) <= Zero then
                  return Orient (Q1, R1, Q2) >= Zero;
               else
                  return False;
               end if;
            else
               return False;
            end if;
         end if;
      else
         if Orient (R2, P2, R1) >= Zero then
            if Orient (Q1, R1, R2) >= Zero then
               return Orient (P1, P2, R1) >= Zero;
            else
               if Orient (Q1, R1, Q2) >= Zero then
                  return Orient (R2, R1, Q2) >= Zero;
               else
                  return False;
               end if;
            end if;
         else
            return False;
         end if;
      end if;
   end Intersection_Test_Vertex;

   ----------------------------
   -- Intersection_Test_Edge --
   ----------------------------

   function Intersection_Test_Edge
     (P1, Q1, R1, P2, Q2, R2 : Point) return Boolean
   is
      pragma Unreferenced (Q2);
   begin
      if Orient (R2, P2, Q1) >= Zero then
         if Orient (P1, P2, Q1) >= Zero then
            return Orient (P1, Q1, R2) >= Zero;
         else
            return Orient (Q1, R1, P2) >= Zero
              and then Orient (R1, P1, P2) >= Zero;
         end if;
      else
         if Orient (R2, P2, R1) >= Zero then
            if Orient (P1, P2, R1) >= Zero then
               return Orient (P1, R1, R2) >= Zero
                 or else Orient (Q1, R1, R2) >= Zero;
            else
               return False;
            end if;
         else
            return False;
         end if;
      end if;
   end Intersection_Test_Edge;

   -------------------------
   -- Tri_Intersection --
   -------------------------

   function Tri_Intersection
     (P1, Q1, R1, P2, Q2, R2 : Point) return Boolean is
   begin
      pragma Warnings
         (Off, "*actuals for this call may be in wrong order");
      if Orient (P2, Q2, P1) >= Zero then
         if Orient (Q2, R2, P1) >= Zero then
            if Orient (R2, P2, P1) >= Zero then
               return True;
            else
               return Intersection_Test_Edge (P1, Q1, R1, P2, Q2, R2);
            end if;
         else
            if Orient (R2, P2, P1) >= Zero then
               return Intersection_Test_Edge (P1, Q1, R1, R2, P2, Q2);
            else
               return Intersection_Test_Vertex (P1, Q1, R1, P2, Q2, R2);
            end if;
         end if;
      else
         if Orient (Q2, R2, P1) >= Zero then
            if Orient (R2, P2, P1) >= Zero then
               return Intersection_Test_Edge (P1, Q1, R1, Q2, R2, P2);
            else
               return Intersection_Test_Vertex (P1, Q1, R1, Q2, R2, P2);
            end if;
         else
            return Intersection_Test_Vertex (P1, Q1, R1, R2, P2, Q2);
         end if;
      end if;
      pragma Warnings
         (On, "*actuals for this call may be in wrong order");
   end Tri_Intersection;

   ---------------
   -- Intersect --
   ---------------
   --  From [TRI]

   function Intersect (T1, T2 : Triangle) return Boolean is
   begin
      if Orient (T1 (1), T1 (2), T1 (3)) < Zero then
         if Orient (T2 (1), T2 (2), T2 (3)) < Zero then
            return Tri_Intersection
              (T1 (1), T1 (3), T1 (2),
               T2 (1), T2 (3), T2 (2));
         else
            return Tri_Intersection
              (T1 (1), T1 (3), T1 (2),
               T2 (1), T2 (2), T2 (3));
         end if;
      else
         if Orient (T2 (1), T2 (2), T2 (3)) < Zero then
            return Tri_Intersection
              (T1 (1), T1 (2), T1 (3),
               T2 (1), T2 (3), T2 (2));
         else
            return Tri_Intersection
              (T1 (1), T1 (2), T1 (3),
               T2 (1), T2 (2), T2 (3));
         end if;
      end if;
   end Intersect;

   ---------------
   -- Intersect --
   ---------------

   function Intersect (R1, R2 : Rectangle) return Boolean is
   begin
      return not
        (R1 (1).X > R2 (2).X           --  R1 on the right of R2
         or else R2 (1).X > R1 (2).X   --  R2 on the right of R1
         or else R1 (1).Y > R2 (2).Y   --  R1 below R2
         or else R2 (1).Y > R1 (2).Y); --  R1 above R2
   end Intersect;

end GNATCOLL.Geometry;