discard """
  matrix: "; --experimental:views"
"""

import std/options

# bug #26058: an element `var T` is a pointer, so `seq[var T]` must not
# match `seq[T]`
type
  Item = object
    id: int

proc touchAll(items: var seq[var Item]) = discard
proc viewLen(items: seq[var int]): int = items.len
proc arr(x: array[2, var int]) = discard
proc plainLen(items: seq[int]): int = items.len

var items = @[Item(id: 0), Item(id: 1)]
var ints = @[1, 2]

doAssert not compiles(touchAll(items))
doAssert not compiles(viewLen(ints))
doAssert not compiles(arr([1, 2]))
doAssert plainLen(ints) == 2

# bug #15533: `lent T` as a generic argument is a different type from `T`, so
# `Option[lent int]` must not accept the `Option[int]` that `some` returns
# (was: C compiler error, the two Option types are distinct C structs)
block:
  var a = [1, 2, 3, 4]
  doAssert not compiles(block:
    let o: Option[lent int] = some(a[0]))
  let p: Option[int] = some(a[0])
  doAssert p.get == 1
