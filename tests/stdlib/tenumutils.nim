import std/enumutils
import std/packedsets

template assertNotCompiling(code: untyped) =
  doAssert not compiles(code)

block:
  intEnumWithHoles:
    type EnumWithHoles = enum A, B, C = 10, D, E = 12, F

  assert EnumWithHoles.low == A
  assert EnumWithHoles.high == F

  assert ord(B) == 1
  assert ord(C) == 10
  assert ord(D) == 11
  assert ord(E) == 12
  assert ord(F) == 13
  assert EnumWithHoles(1)  == B
  assert EnumWithHoles(10) == C
  assert EnumWithHoles(11) == D
  assert EnumWithHoles(12) == E
  assert EnumWithHoles(13) == F

  assert not compiles(EnumWithHoles(100))

  var x: array[EnumWithHoles, string]
  var enumSet: PackedSet[EnumWithHoles]

import macros

block negativeRange:
  intEnumWithHoles:
    type NegativeIndexes = enum X = -3, Y = -1

  var enumSet: PackedSet[NegativeIndexes]

block charEnums:
  intEnumWithHoles:
    type CharEnum = enum A = 'a', B, E = 'e'

  assert char(E) == 'e'
  assert CharEnum('e') == E
  var x: array[CharEnum, string]

assertNotCompiling:
  type CharEnum = enum A = 'a', B, E = 'e'
  var x: array[CharEnum, string]

assertNotCompiling:
  intEnumWithHoles:
    type UnorderedCharEnum = enum A = 'c', B, C = 'a'

assertNotCompiling:
  intEnumWithHoles:
    type Unordered = enum A, B, C = 12, E, D = 11, F

assertNotCompiling:
  intEnumWithHoles:
    type Unordered = enum A = -1, B = -2

assertNotCompiling:
  intEnumWithHoles:
    type TooSparse = enum A, B, C = 300, D

block isDefined:
  intEnumWithHoles:
    type Letters = enum J = 'j', K, Z = 'z'

  assert not isDefined(Letters('a'))
  assert isDefined(Letters('j'))
  assert isDefined(Letters('k'))
  assert not isDefined(Letters('h'))
  assert isDefined(Letters('z'))

block safeIteration:
  intEnumWithHoles:
    type Holed = enum A, B = 10, F = 15

  var inHoled: PackedSet[Holed]

  for e in definedItems(Holed):
    inHoled.incl(e)

  assert inHoled == [A, B, F].toPackedSet
