discard """
  errormsg: "type mismatch"
  line: 116
"""

# bug #2169
import strutils, math

type
  Point2D*[S] = object
    x*, y*: S
  Matrix2x3*[S] = distinct array[6, S] ## Row major order

  Vector2D*[S] = object
    x*, y*: S

proc `[]`*[T](m: Matrix2x3[T], i: int): T = array[6, T](m)[i]

template M11*[T](m: Matrix2x3[T]): T = m[0]
template M12*[T](m: Matrix2x3[T]): T = m[1]
template M13*[T](m: Matrix2x3[T]): T = m[2]
template M21*[T](m: Matrix2x3[T]): T = m[3]
template M22*[T](m: Matrix2x3[T]): T = m[4]
template M23*[T](m: Matrix2x3[T]): T = m[5]

proc identity*[T](): Matrix2x3[T] =
    Matrix2x3[T]([T(1.0), 0.0, 0.0,   0.0, 1.0, 0.0])

proc translation*[T](p: Point2D[T]): Matrix2x3[T] =
    Matrix2x3[T]([T(1.0), T(0.0), p.x, T(0.0), T(1.0), p.y])

proc translation*[T](p: Vector2D[T]): Matrix2x3[T] =
    Matrix2x3[T]([T(1.0), T(0.0), p.x, T(0.0), T(1.0), p.y])

proc scale*[T](v: Vector2D[T]): Matrix2x3[T] =
    Matrix2x3[T]([v.x, T(0.0), T(0.0), T(0.0), v.y, T(0.0)])

proc rotation*[T](th: T): Matrix2x3[T] =
    let
        c = T(cos(th.float))
        s = T(sin(th.float))

    Matrix2x3[T]([c, -s, T(0.0),   s, c, T(0.0)])

proc `*`*[T](a, b: Matrix2x3[T]): Matrix2x3[T] =
    # Here we pretend that row 3 is [0,0,0,1] without
    # actually storing it in the matrix.
    Matrix2x3[T]([a.M11*b.M11 + a.M12*b.M21,
                  a.M11*b.M12 + a.M12*b.M22,
                  a.M11*b.M13 + a.M12*b.M23 + a.M13,

                  a.M21*b.M11 + a.M22*b.M21,
                  a.M21*b.M12 + a.M22*b.M22,
                  a.M21*b.M13 + a.M22*b.M23 + a.M23])

proc `*`*[T](a: Matrix2x3[T], p: Point2D[T]): Point2D[T] =
    let
        x = a.M11*p.x + a.M12*p.y + a.M13
        y = a.M21*p.x + a.M22*p.y + a.M23

    Point2D[T](x: x, y: y)

# making these so things like "line" that need a constructor don't stick out.
# 2x2 determinant:  |a b|
#                   |c d|  = ad - bc

# String rendering
#
template ff[S](x: S): string =
    formatFloat(float(x), ffDefault, 0)

proc `$`*[S](p: Point2D[S]): string =
    "P($1, $2)" % [ff(p.x), ff(p.y)]

proc `$`*[S](p: Vector2D[S]): string =
    "V($1, $2)" % [ff(p.x), ff(p.y)]

proc `$`*[S](m: Matrix2x3[S]): string =
    "M($1 $2 $3/$4 $5 $6)" % [ff(m.M11), ff(m.M12), ff(m.M13),
                              ff(m.M21), ff(m.M22), ff(m.M23)]

#
# Vector operators.
proc `-`*[S](a: Vector2D[S]): Vector2D[S] =
  Vector2D[S](x: -a.x, y: -a.y)

proc `+`*[S](a, b: Vector2D[S]): Vector2D[S] =
  Vector2D[S](x: a.x + b.x, y: a.y + b.y)

proc `-`*[S](a, b: Vector2D[S]): Vector2D[S] =
  Vector2D[S](x: a.x - b.x, y: a.y - b.y)

proc `*`*[S](v: Vector2D[S], sc: S): Vector2D[S] =
  Vector2D[S](x: v.x*sc, y: v.y*sc)

proc `*`*[S](sc: S, v: Vector2D[S]): Vector2D[S] =
  Vector2D[S](x: v.x*sc, y: v.y*sc)

proc `/`*[S](v: Vector2D[S], sc: S): Vector2D[S] =
  Vector2D[S](x: v.x/sc, y: v.y/sc)

proc `/`*[S](sc: S; v: Vector2D[S]): Vector2D[S] =
  Vector2D[S](x: sc/v.x, y: sc/v.y)

proc `/`*[S](a, b: Vector2D[S]): Vector2D[S] =
  Vector2D[S](x: a.x/b.x, y: a.y/b.y)
#proc vec[S](x, y: S): Vector2D[S]
proc vec[S](x, y: S): Vector2D[S] =
  Vector2D[S](x: x, y: y)

if true:
  # Comment out this let, and the program will fail to
  # compile with a type mismatch, as expected.

  let s3 = scale(vec(4.0, 4.0))
  let barf = translation(Point2D[float32](x: 1, y: 1)) * rotation(float(0.7))

  echo "Badness ", barf
