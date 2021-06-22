#[
benchmark for digits10

on OSX, `nim r -d:danger tests/benchmarks/tdigits10.nim` prints:
("digits10v1", 1718245139, 0.567017)
("digits10", 1718245139, 0.16170099999999998)

without {.noinline.} in digits10v1:
("digits10v1", 1718245139, 0.43684399999999995)
("digits10", 1718245139, 0.15965100000000004)
]#

from system {.all.} import digits10

func digits10v1(num: uint64): int {.noinline.} = # a bit 
# func digits10v1(num: uint64): int =
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
    result = 12 + digits10v1(num div 1_000_000_000_000'u64)

import std/times

template main2(algo) =
  block:
    let n = 100_000_000
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
    doAssert c == 1718245139 # adjust as needed

proc main =
  for i in 0..<3:
    main2(digits10v1)
    main2(digits10)
main()
