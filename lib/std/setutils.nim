#
#
#           The Nim Compiler
#        (c) Copyright 2020 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module adds functionality for the built-in `set` type.
##
## See also
## ========
## * `std/packedsets <packedsets.html>`_
## * `std/sets <sets.html>`_

import typetraits, macros

#[
  type SetElement* = char|byte|bool|int16|uint16|enum|uint8|int8
    ## The allowed types of a built-in set.
]#

template toSet*[T: set](iter: untyped, _: typedesc[T]): T =
  ## Returns a built-in set from the elements of the iterable `iter`.
  runnableExamples:
    var s1: set['a'..'z'] = {'a', 'c'}
    var s2: set[char] = {'a', 'b'}
    assert not compiles(s1 + s2) # incompatible type
    s1 = s1 + s2.toSet(typeof(s1))
    var s3: set['a'..'z'] = {'a', 'b', 'c'}
    assert s1 == s3
    assert "abc".toSet(set['a'..'z']) == s3
    doAssertRaises(RangeDefect): discard "abc".toSet(set['a'..'b'])
  # xxx `s1 == {'a', 'b', 'c'}` fails in above example;
  # it should either succeed or give CT error, refs bug #18396
  var result: T
  for x in iter:
    incl(result, x)
  result

template toSet*(iter: untyped): untyped =
  ## Overload that infers the set type.
  runnableExamples:
    assert "helloWorld".toSet == {'W', 'd', 'e', 'h', 'l', 'o', 'r'}
    assert toSet([10u16, 20, 30]) == {10u16, 20, 30}
    assert [30u8, 100, 10].toSet == {10u8, 30, 100}
    assert toSet(@[1321i16, 321, 90]) == {90i16, 321, 1321}
    assert toSet([false]) == {false}
    assert toSet(0u8..10) == {0u8..10}
  toSet(iter, set[elementType(iter)])

macro enumElementsAsSet(enm: typed): untyped = result = newNimNode(nnkCurly).add(enm.getType[1][1..^1])

# func fullSet*(T: typedesc): set[T] {.inline.} = # xxx would give: Error: ordinal type expected
func fullSet*[T](U: typedesc[T]): set[T] {.inline.} =
  ## Returns a set containing all elements in `U`.
  runnableExamples:
    assert bool.fullSet == {true, false}
    type A = range[1..3]
    assert A.fullSet == {1.A, 2, 3}
    assert int8.fullSet.len == 256
  when T is Ordinal:
    {T.low..T.high}
  else: # Hole filled enum
    enumElementsAsSet(T)

func complement*[T](s: set[T]): set[T] {.inline.} =
  ## Returns the set complement of `a`.
  runnableExamples:
    type Colors = enum
      red, green = 3, blue
    assert complement({red, blue}) == {green}
    assert complement({red, green, blue}).card == 0
    assert complement({range[0..10](0), 1, 2, 3}) == {range[0..10](4), 5, 6, 7, 8, 9, 10}
    assert complement({'0'..'9'}) == {0.char..255.char} - {'0'..'9'}
  fullSet(T) - s

func `[]=`*[T](t: var set[T], key: T, val: bool) {.inline.} =
  ## Syntax sugar for `if val: t.incl key else: t.excl key`
  runnableExamples:
    type A = enum
      a0, a1, a2, a3
    var s = {a0, a3}
    s[a0] = false
    s[a1] = false
    assert s == {a3}
    s[a2] = true
    s[a3] = true
    assert s == {a2, a3}
  if val: t.incl key else: t.excl key
