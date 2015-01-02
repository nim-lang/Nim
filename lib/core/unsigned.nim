#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements basic arithmetic operators for unsigned integers.
## To discourage users from using ``unsigned``, it's not part of ``system``,
## but an extra import.

proc `not`*[T: SomeUnsignedInt](x: T): T {.magic: "BitnotI", noSideEffect.}
  ## computes the `bitwise complement` of the integer `x`.

proc `shr`*[T: SomeUnsignedInt](x, y: T): T {.magic: "ShrI", noSideEffect.}
  ## computes the `shift right` operation of `x` and `y`.

proc `shl`*[T: SomeUnsignedInt](x, y: T): T {.magic: "ShlI", noSideEffect.}
  ## computes the `shift left` operation of `x` and `y`.

proc `and`*[T: SomeUnsignedInt](x, y: T): T {.magic: "BitandI", noSideEffect.}
  ## computes the `bitwise and` of numbers `x` and `y`.

proc `or`*[T: SomeUnsignedInt](x, y: T): T {.magic: "BitorI", noSideEffect.}
  ## computes the `bitwise or` of numbers `x` and `y`.

proc `xor`*[T: SomeUnsignedInt](x, y: T): T {.magic: "BitxorI", noSideEffect.}
  ## computes the `bitwise xor` of numbers `x` and `y`.

proc `==`*[T: SomeUnsignedInt](x, y: T): bool {.magic: "EqI", noSideEffect.}
  ## Compares two unsigned integers for equality.

proc `+`*[T: SomeUnsignedInt](x, y: T): T {.magic: "AddU", noSideEffect.}
  ## Binary `+` operator for unsigned integers.

proc `-`*[T: SomeUnsignedInt](x, y: T): T {.magic: "SubU", noSideEffect.}
  ## Binary `-` operator for unsigned integers.

proc `*`*[T: SomeUnsignedInt](x, y: T): T {.magic: "MulU", noSideEffect.}
  ## Binary `*` operator for unsigned integers.

proc `div`*[T: SomeUnsignedInt](x, y: T): T {.magic: "DivU", noSideEffect.}
  ## computes the integer division. This is roughly the same as
  ## ``floor(x/y)``.

proc `mod`*[T: SomeUnsignedInt](x, y: T): T {.magic: "ModU", noSideEffect.}
  ## computes the integer modulo operation. This is the same as
  ## ``x - (x div y) * y``.

proc `<=`*[T: SomeUnsignedInt](x, y: T): bool {.magic: "LeU", noSideEffect.}
  ## Returns true iff ``x <= y``.

proc `<`*[T: SomeUnsignedInt](x, y: T): bool {.magic: "LtU", noSideEffect.}
  ## Returns true iff ``unsigned(x) < unsigned(y)``.

