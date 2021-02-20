discard """
  action: compile
"""

#[
## on osx
nim r -d:danger --threads --tlsEmulation:off tests/benchmarks/ttls.nim
9.999999999992654e-07

ditto with `--tlsEmulation:on`:
0.216999
]#

import times

proc main2(): int =
  var g0 {.threadvar.}: int
  g0.inc
  result = g0

proc main =
  let n = 100_000_000
  var c = 0
  let t = cpuTime()
  for i in 0..<n:
    c += main2()
  let t2 = cpuTime() - t
  doAssert c != 0
  echo t2
main()
