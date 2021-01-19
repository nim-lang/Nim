discard """
  matrix: "-d:nimTtlsemulationCase1 --threads --tlsEmulation:on; -d:nimTtlsemulationCase2 --threads --tlsEmulation:off; -d:nimTtlsemulationCase3 --threads"
  targets: "c cpp"
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

when defined(cpp):
  block:
    type Foo1 {.importcpp: "Foo1", header: "mtlsemulation.h".} = object
      x: cint
    type Foo2 {.cppNonPod, importcpp: "Foo2", header: "mtlsemulation.h".} = object
      x: cint
    proc main() =
      var g1 {.threadvar.}: Foo1
      var g2 {.threadvar.}: Foo2
      discard g1
      discard g2
    main()
