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

import std/typetraits

#[
  type SetElement* = char|byte|bool|int16|uint16|enum|uint8|int8
    ## The allowed types of a built-in set.
]#

template toSet*(iter: untyped): untyped =
  ## Returns a built-in set from the elements of the iterable `iter`.
  runnableExamples:
    assert "helloWorld".toSet == {'W', 'd', 'e', 'h', 'l', 'o', 'r'}
    assert toSet([10u16, 20, 30]) == {10u16, 20, 30}
    assert [30u8, 100, 10].toSet == {10u8, 30, 100}
    assert toSet(@[1321i16, 321, 90]) == {90i16, 321, 1321}
    assert toSet([false]) == {false}
    assert toSet(0u8..10) == {0u8..10}

  var result: set[elementType(iter)]
  for x in iter:
    incl(result, x)
  result

proc `not`*[T](s: set[T]): set[T] = 
  ## Returns the complement of the set.
  ## Can also be thought of as inverting the set.
  runnableExamples:
    type Colors = enum
      red, green, blue
    assert {red, blue}.not == {green}
    assert (not {red, green, blue}).card == 0
    assert {range[0..10](0), 1, 2, 3}.not == {range[0..10](4), 5, 6, 7, 8, 9, 10}
    assert {'0'..'9'}.not == {0.char..255.char} - {'0'..'9'}
  {T.low..T.high} - s
