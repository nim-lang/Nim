discard """
  matrix: "-d:nimTtlsemulationCase1 --threads --tlsEmulation:on; -d:nimTtlsemulationCase2 --threads --tlsEmulation:off; -d:nimTtlsemulationCase3 --threads"
"""

import std/sugar

block:
  # makes sure the logic in config/nim.cfg or testament doesn't interfere with `--tlsEmulation` so we test the right thing.
  when defined(nimTtlsemulationCase1):
    doAssert compileOption("tlsEmulation")
  elif defined(nimTtlsemulationCase2):
    doAssert not compileOption("tlsEmulation")
  elif defined(nimTtlsemulationCase3):
    when defined(osx):
      doAssert not compileOption("tlsEmulation")
  else:
    doAssert false

block:
  proc main(): int =
    var g0 {.threadvar.}: int
    g0.inc
    g0
  let s = collect:
    for i in 0..<3: main()
  doAssert s == @[1,2,3]
