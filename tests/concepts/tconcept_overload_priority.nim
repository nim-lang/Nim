discard """
  action: run
"""

# The choice between a routine declared over a concept and a concrete overload
# must not depend on how many requirements the concept happens to declare.
#
# `sumGeneric` ranks concepts by requirement count, and concrete types by
# structural nesting depth, which makes sense within each category but not
# between one another. So we must make sure we don't fall through that case
# accidentally picking ambiguous calls arbitrarily (see GitHub issue #26147).

type
  Small[T] = concept
    proc `[]`(a: Self; index: int): T
    proc len(a: Self): int

  Large[T] = concept
    proc `[]`(a: Self; index: int): T
    proc len(a: Self): int
    proc extra1(a: Self): int
    proc extra2(a: Self): int
    proc extra3(a: Self): int

  Box[T] = ref object
    data: seq[T]

proc `[]`[T](b: Box[T], i: int): T = b.data[i]
proc len[T](b: Box[T]): int = b.data.len
proc extra1[T](b: Box[T]): int = 0
proc extra2[T](b: Box[T]): int = 0
proc extra3[T](b: Box[T]): int = 0

proc pickSmall[T](x: Small[T]): string = "concept"
proc pickSmall[T](x: Box[T]): string = "concrete"

proc pickLarge[T](x: Large[T]): string = "concept"
proc pickLarge[T](x: Box[T]): string = "concrete"

let b = Box[int](data: @[1, 2, 3])

# `Box` satisfies both concepts, so both calls must select the concrete
# overload, and must agree with each other.
doAssert pickSmall(b) == "concrete"
doAssert pickLarge(b) == "concrete"
doAssert pickSmall(b) == pickLarge(b)
