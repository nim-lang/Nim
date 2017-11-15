#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf, Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module offers implementations of common binary operations
## like ``+``, ``-``, ``*``, ``/`` and comparison operations,
## which work for mixed float/int operands.
## All operations convert the integer operand into the
## type of the float operand. For numerical expressions, the return
## type is always the type of the float involved in the expresssion,
## i.e., there is no auto conversion from float32 to float64.
##
## Note: In general, auto-converting from int to float loses
## information, which is why these operators live in a separate
## module. Use with care.


proc `+`[I: SomeInteger, F: SomeReal](i: I, f: F): F = F(i) + f
proc `+`[I: SomeInteger, F: SomeReal](f: F, i: I): F = f + F(i)

proc `-`[I: SomeInteger, F: SomeReal](i: I, f: F): F = F(i) - f
proc `-`[I: SomeInteger, F: SomeReal](f: F, i: I): F = f - F(i)

proc `*`[I: SomeInteger, F: SomeReal](i: I, f: F): F = F(i) * f
proc `*`[I: SomeInteger, F: SomeReal](f: F, i: I): F = f * F(i)

proc `/`[I: SomeInteger, F: SomeReal](i: I, f: F): F = F(i) / f
proc `/`[I: SomeInteger, F: SomeReal](f: F, i: I): F = f / F(i)

proc `<`[I: SomeInteger, F: SomeReal](i: I, f: F): bool = F(i) < f
proc `<`[I: SomeInteger, F: SomeReal](f: F, i: I): bool = f < F(i)
proc `<=`[I: SomeInteger, F: SomeReal](i: I, f: F): bool = F(i) <= f
proc `<=`[I: SomeInteger, F: SomeReal](f: F, i: I): bool = f <= F(i)
proc `==`[I: SomeInteger, F: SomeReal](i: I, f: F): bool = F(i) == f
proc `==`[I: SomeInteger, F: SomeReal](f: F, i: I): bool = f == F(i)
proc `>=`[I: SomeInteger, F: SomeReal](i: I, f: F): bool = F(i) >= f
proc `>=`[I: SomeInteger, F: SomeReal](f: F, i: I): bool = f >= F(i)
proc `>`[I: SomeInteger, F: SomeReal](i: I, f: F): bool = F(i) > f
proc `>`[I: SomeInteger, F: SomeReal](f: F, i: I): bool = f > F(i)

when isMainModule:

  proc `~=`[T](a, b: T): bool = abs(a - b) < 1e-7

  block: # math binary operators
    let i = 1
    let f = 2.0

    doAssert i + f ~= 3
    doAssert f + i ~= 3

    doAssert i - f ~= -1
    doAssert f - i ~= 1

    doAssert i * f ~= 2
    doAssert f * i ~= 2

    doAssert i / f ~= 0.5
    doAssert f / i ~= 2

  block: # comparison operators
    doAssert 1.int < 2.float
    doAssert 1.float < 2.int
    doAssert 1.int <= 2.float
    doAssert 1.float <= 2.int
    doAssert 1.int == 1.float
    doAssert 1.float == 1.int
    doAssert 2.int >= 1.float
    doAssert 2.float >= 1.int
    doAssert 2.int > 1.float
    doAssert 2.float > 1.int

  block: # all type combinations
    let i = 1
    let f = 2.0

    doAssert i.int + f.float ~= 3
    doAssert i.int + f.float32 ~= 3
    doAssert i.int + f.float64 ~= 3
    doAssert i.int8 + f.float ~= 3
    doAssert i.int8 + f.float32 ~= 3
    doAssert i.int8 + f.float64 ~= 3
    doAssert i.int16 + f.float ~= 3
    doAssert i.int16 + f.float32 ~= 3
    doAssert i.int16 + f.float64 ~= 3
    doAssert i.int32 + f.float ~= 3
    doAssert i.int32 + f.float32 ~= 3
    doAssert i.int32 + f.float64 ~= 3
    doAssert i.int64 + f.float ~= 3
    doAssert i.int64 + f.float32 ~= 3
    doAssert i.int64 + f.float64 ~= 3
    doAssert i.uint + f.float ~= 3
    doAssert i.uint + f.float32 ~= 3
    doAssert i.uint + f.float64 ~= 3
    doAssert i.uint8 + f.float ~= 3
    doAssert i.uint8 + f.float32 ~= 3
    doAssert i.uint8 + f.float64 ~= 3
    doAssert i.uint16 + f.float ~= 3
    doAssert i.uint16 + f.float32 ~= 3
    doAssert i.uint16 + f.float64 ~= 3
    doAssert i.uint32 + f.float ~= 3
    doAssert i.uint32 + f.float32 ~= 3
    doAssert i.uint32 + f.float64 ~= 3
    doAssert i.uint64 + f.float ~= 3
    doAssert i.uint64 + f.float32 ~= 3
    doAssert i.uint64 + f.float64 ~= 3

    doAssert f.float + i.int  ~= 3
    doAssert f.float32 + i.int ~= 3
    doAssert f.float64 + i.int ~= 3
    doAssert f.float + i.int8 ~= 3
    doAssert f.float32 + i.int8 ~= 3
    doAssert f.float64 + i.int8 ~= 3
    doAssert f.float + i.int16 ~= 3
    doAssert f.float32 + i.int16 ~= 3
    doAssert f.float64 + i.int16 ~= 3
    doAssert f.float + i.int32 ~= 3
    doAssert f.float32 + i.int32 ~= 3
    doAssert f.float64 + i.int32 ~= 3
    doAssert f.float + i.int64 ~= 3
    doAssert f.float32 + i.int64 ~= 3
    doAssert f.float64 + i.int64 ~= 3
    doAssert f.float + i.uint ~= 3
    doAssert f.float32 + i.uint ~= 3
    doAssert f.float64 + i.uint ~= 3
    doAssert f.float + i.uint8 ~= 3
    doAssert f.float32 + i.uint8 ~= 3
    doAssert f.float64 + i.uint8 ~= 3
    doAssert f.float + i.uint16 ~= 3
    doAssert f.float32 + i.uint16 ~= 3
    doAssert f.float64 + i.uint16 ~= 3
    doAssert f.float + i.uint32 ~= 3
    doAssert f.float32 + i.uint32 ~= 3
    doAssert f.float64 + i.uint32 ~= 3
    doAssert f.float + i.uint64 ~= 3
    doAssert f.float32 + i.uint64 ~= 3
    doAssert f.float64 + i.uint64 ~= 3
