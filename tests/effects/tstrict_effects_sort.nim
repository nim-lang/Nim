discard """
  errormsg: "cmpE can raise an unlisted exception: Exception"
  line: 27
"""

{.push warningAsError[Effect]: on.}

{.experimental: "strictEffects".}

import algorithm

type
  MyInt = distinct int

var toSort = @[MyInt 1, MyInt 2, MyInt 3]

proc cmpN(a, b: MyInt): int =
  cmp(a.int, b.int)

proc harmless {.raises: [].} =
  toSort.sort cmpN

proc cmpE(a, b: MyInt): int {.raises: [Exception].} =
  cmp(a.int, b.int)

proc harmfull {.raises: [].} =
  toSort.sort cmpE
