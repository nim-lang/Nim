discard """
  action: compile
"""

#[
benchmark for digits10

on OSX, `nim r -d:danger tests/benchmarks/tdigits10.nim` prints:
("digits10", 18976262687, 1.685551)
("digits10v2", 18976262687, 6.813552)

without {.noinline.} in digits10v2:
("digits10", 18976262687, 1.886009)
("digits10v2", 18976262687, 5.0835799999999995)
]#

from std/private/digitsutils import digits10

func digits10v2(num: uint64): int {.noinline.} =
# func digits10v2(num: uint64): int = # a bit faster without {.noinline.}
  if num < 10'u64:
    result = 1
  elif num < 100'u64:
    result = 2
  elif num < 1_000'u64:
    result = 3
  elif num < 10_000'u64:
    result = 4
  elif num < 100_000'u64:
    result = 5
  elif num < 1_000_000'u64:
    result = 6
  elif num < 10_000_000'u64:
    result = 7
  elif num < 100_000_000'u64:
    result = 8
  elif num < 1_000_000_000'u64:
    result = 9
  elif num < 10_000_000_000'u64:
    result = 10
  elif num < 100_000_000_000'u64:
    result = 11
  elif num < 1_000_000_000_000'u64:
    result = 12
  else:
    result = 12 + digits10v2(num div 1_000_000_000_000'u64)

import std/times

var c0 = 0
template main2(algo) =
  block:
    let n = 1000_000_000
    var c = 0
    let t = cpuTime()
    template gen(i): untyped =
      # pseudo-random but fast
      var x = cast[uint64](i)
      x + (x*x shl 5)
    for i in 1..<n:
      let x = gen(i)
      c += algo(x)
    let t2 = cpuTime()
    echo (astToStr(algo), c, t2 - t)
    # sanity check
    if c0 == 0: c0 = c
    else: doAssert c == c0

proc main =
  for i in 0..<3:
    main2(digits10)
    main2(digits10v2)
main()
