#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements basic arithmetic operators for unsigned integers.
## To discourage users from using ``unsigned``, it's not part of ``system``,
## but an extra import.

type
  SomeUInt = uint|uint8|uint16|uint32|uint64

proc `not`*[T: SomeUInt](x: T): T {.magic: "BitnotI", noSideEffect.}
  ## computes the `bitwise complement` of the integer `x`.

proc `shr`*[T: SomeUInt](x, y: T): T {.magic: "ShrI", noSideEffect.}
  ## computes the `shift right` operation of `x` and `y`.

proc `shl`*[T: SomeUInt](x, y: T): T {.magic: "ShlI", noSideEffect.}
  ## computes the `shift left` operation of `x` and `y`.

proc `and`*[T: SomeUInt](x, y: T): T {.magic: "BitandI", noSideEffect.}
  ## computes the `bitwise and` of numbers `x` and `y`.

proc `or`*[T: SomeUInt](x, y: T): T {.magic: "BitorI", noSideEffect.}
  ## computes the `bitwise or` of numbers `x` and `y`.

proc `xor`*[T: SomeUInt](x, y: T): T {.magic: "BitxorI", noSideEffect.}
  ## computes the `bitwise xor` of numbers `x` and `y`.

proc `==`*[T: SomeUInt](x, y: T): bool {.magic: "EqI", noSideEffect.}
  ## Compares two unsigned integers for equality.

proc `+`*[T: SomeUInt](x, y: T): T {.magic: "AddU", noSideEffect.}
  ## Binary `+` operator for unsigned integers.

proc `-`*[T: SomeUInt](x, y: T): T {.magic: "SubU", noSideEffect.}
  ## Binary `-` operator for unsigned integers.

proc `*`*[T: SomeUInt](x, y: T): T {.magic: "MulU", noSideEffect.}
  ## Binary `*` operator for unsigned integers.

proc `div`*[T: SomeUInt](x, y: T): T {.magic: "DivU", noSideEffect.}
  ## computes the integer division. This is roughly the same as
  ## ``floor(x/y)``.

proc `mod`*[T: SomeUInt](x, y: T): T {.magic: "ModU", noSideEffect.}
  ## computes the integer modulo operation. This is the same as
  ## ``x - (x div y) * y``.

proc `<=`*[T: SomeUInt](x, y: T): bool {.magic: "LeU", noSideEffect.}
  ## Returns true iff ``x <= y``.

proc `<`*[T: SomeUInt](x, y: T): bool {.magic: "LtU", noSideEffect.}
  ## Returns true iff ``unsigned(x) < unsigned(y)``.

proc `+=`*[T: uint|uint64](x: var T, y: T) {.magic: "Inc", noSideEffect.}
  ## Increments uints and uint64s, uint8..uint32 are TOrdinals, and already
  ## have a definition in the System module.

proc `-=`*[T: uint|uint64](x: var T, y: T) {.magic: "Dec", noSideEffect.}
  ## Decrements uints and uint64s, uint8..uint32 are TOrdinals, and already
  ## have a definition in the System module.

proc `*=`*[T: uint|uint64](x: var T, y: T) {.inline, noSideEffect.} =
  ## Binary `*=` operator for uints and uint64s, uint8..uint32 are TOrdinals,
  ## and already have a definition in the System module.
  x = x * y
