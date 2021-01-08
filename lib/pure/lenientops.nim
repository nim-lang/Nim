#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module offers implementations of common binary operations
## like `+`, `-`, `*`, `/` and comparison operations,
## which work for mixed float/int operands.
## All operations convert the integer operand into the
## type of the float operand. For numerical expressions, the return
## type is always the type of the float involved in the expression,
## i.e., there is no auto conversion from float32 to float64.
##
## **Note:** In general, auto-converting from int to float loses
## information, which is why these operators live in a separate
## module. Use with care.
##
## Regarding binary comparison, this module only provides unequal operators.
## The equality operator `==` is omitted, because depending on the use case
## either casting to float or rounding to int might be preferred, and users
## should make an explicit choice.

func `+`*[I: SomeInteger, F: SomeFloat](i: I, f: F): F {.inline.} =
  F(i) + f
func `+`*[I: SomeInteger, F: SomeFloat](f: F, i: I): F {.inline.} =
  f + F(i)

func `-`*[I: SomeInteger, F: SomeFloat](i: I, f: F): F {.inline.} =
  F(i) - f
func `-`*[I: SomeInteger, F: SomeFloat](f: F, i: I): F {.inline.} =
  f - F(i)

func `*`*[I: SomeInteger, F: SomeFloat](i: I, f: F): F {.inline.} =
  F(i) * f
func `*`*[I: SomeInteger, F: SomeFloat](f: F, i: I): F {.inline.} =
  f * F(i)

func `/`*[I: SomeInteger, F: SomeFloat](i: I, f: F): F {.inline.} =
  F(i) / f
func `/`*[I: SomeInteger, F: SomeFloat](f: F, i: I): F {.inline.} =
  f / F(i)

func `<`*[I: SomeInteger, F: SomeFloat](i: I, f: F): bool {.inline.} =
  F(i) < f
func `<`*[I: SomeInteger, F: SomeFloat](f: F, i: I): bool {.inline.} =
  f < F(i)
func `<=`*[I: SomeInteger, F: SomeFloat](i: I, f: F): bool {.inline.} =
  F(i) <= f
func `<=`*[I: SomeInteger, F: SomeFloat](f: F, i: I): bool {.inline.} =
  f <= F(i)

# Note that we must not defined `>=` and `>`, because system.nim already has a
# template with signature (x, y: untyped): untyped, which would lead to
# ambiguous calls.
