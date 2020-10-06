##[
Convenience procs to deal with pointer-like variables.
]##

proc toUncheckedArray*[T](a: ptr[T]): ptr UncheckedArray[T] {.inline.} =
  ## calls `cast[ptr UncheckedArray[T]]` (less error prone).
  runnableExamples:
    var a = @[10, 11, 12]
    let pa = a[1].addr.toUncheckedArray
    doAssert pa[-1] == 10
    pa[0] = 100
    doAssert a == @[10, 100, 12]
    pa[0] += 5
    doAssert a[1] == 105
  cast[ptr UncheckedArray[T]](a)
