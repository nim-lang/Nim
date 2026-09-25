# Test that set[] accepts range types via typedesc[R], and set[typedesc[R]]
# must unwrap the typedesc wrapper before checking ordinality.

import std/typetraits

type
  TestDistinctRange = distinct range[0 .. 63]

block: # explicit range type as set base
  type S = set[range[0 .. 63]]
  var s: S = {0, 1}
  doAssert 0 in s

block: # distinctBase result as set base (non-generic)
  type S = set[TestDistinctRange.distinctBase]
  var s: S = {0, 1}
  doAssert 0 in s

block: # range alias as set base
  type RangeAlias = range[0 .. 63]
  type S = set[RangeAlias]
  var s: S = {0, 1}
  doAssert 0 in s

block: # set[T.distinctBase] in generic body type position
  proc test[T: TestDistinctRange]() =
    var s: set[T.distinctBase]
    s = {0, 1}
    doAssert 0 in s

  test[TestDistinctRange]()

block: # passing set[T.distinctBase] to a proc expecting set[0..63]
  proc accept(x: typedesc[set[0 .. 63]]) = discard

  proc pass[T: TestDistinctRange](p: typedesc[set[T]]) =
    accept(set[T.distinctBase])

  pass(set[TestDistinctRange])
