#
#
#           The Nim Compiler
#        (c) Copyright 2020 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module adds functionality to the default set

import typetraits

type SetElement* = char|byte|bool|int16|uint16|enum|int8

template toSet*(iter: untyped): untyped =
  ##Iterates through an openArray making a set from it.
  runnableExamples: 
    assert "helloWorld".toSet == {'W', 'd', 'e', 'h', 'l', 'o', 'r'}
    assert toSet([10u16,20,30]) == {10u16, 20, 30}
    assert [30u8,100,10].toSet == {10u8, 30, 100}
    assert toSet(@[1321i16,321, 90]) == {90i16, 321, 1321}
    assert toSet([false]) == {false}
    assert toSet(0u8..10u8) == {0u8..10u8}
  when compiles(elementType(iter)):
    when elementType(iter) isnot SetElement: {.error: "Iterator does not yield a `SetElement`".}
    else:
      var result: set[elementType(iter)]
      for x in iter:
        result.incl(x)
      result
  else: {.error: "`toSet` can only be used on iteratable types.".}

