discard """
  matrix: "-u:nimPreviewNonVarDestructor;"
"""
type DistinctSeq* = distinct seq[int]

# `=destroy`(cast[ptr DistinctSeq](0)[])
var x = @[].DistinctSeq
`=destroy`(x)


import std/options

# bug #24801
type
  B[T] = object
    case r: bool
    of false:
      v: ref int
    of true:
      x: T
  E = distinct seq[int]
  U = ref object of RootObj
  G = ref object of U

proc a(): E = default(E)
method c(_: U): seq[E] {.base.} = discard
proc p(): seq[E] = c(default(U))
method c(_: G): seq[E] = discard E(newSeq[seq[int]](1)[0])
method y(_: U) {.base.} =
  let s = default(B[tuple[f: B[int], w: B[int]]])
  discard some(s.x)
