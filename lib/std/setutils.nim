#
#
#           The Nim Compiler
#        (c) Copyright 2020 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module adds functionality to the builtin set
## See also std/packedsets, setd/sets

import typetraits

type SetElement* = char|byte|bool|int16|uint16|enum|uint8|int8
  ## The allowed types of a builtin set.

template toSet*(iter: untyped): untyped =
  ## Return a builtin set from the elements of iterable `iter`
  ## Example: "ab".toSet == {'a','b'} 
  runnableExamples: 
    assert "helloWorld".toSet == {'W', 'd', 'e', 'h', 'l', 'o', 'r'}
    assert toSet([10u16,20,30]) == {10u16, 20, 30}
    assert [30u8,100,10].toSet == {10u8, 30, 100}
    assert toSet(@[1321i16,321, 90]) == {90i16, 321, 1321}
    assert toSet([false]) == {false}
    assert toSet(0u8..10u8) == {0u8..10u8}
  type E = elementType(iter)
  static: doAssert E is SetElement, "`iter` does not yield a `SetElement`"
  var result: set[E]
  for x in iter:
    result.incl(x)
  result
