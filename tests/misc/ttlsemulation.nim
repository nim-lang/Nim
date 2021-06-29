discard """
  matrix: "-d:nimTtlsemulationCase1 --threads --tlsEmulation:on; -d:nimTtlsemulationCase2 --threads --tlsEmulation:off; -d:nimTtlsemulationCase3 --threads"
  targets: "c cpp"
"""

#[
tests for: `.cppNonPod`, `--tlsEmulation`
]#

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
  proc main1(): int =
    var g0 {.threadvar.}: int
    g0.inc
    g0
  let s = collect:
    for i in 0..<3: main1()
  doAssert s == @[1,2,3]

when defined(cpp): # bug #16752
  when defined(windows) and defined(nimTtlsemulationCase2):
    discard # xxx this failed with exitCode 1
  else:
    type Foo1 {.importcpp: "Foo1", header: "mtlsemulation.h".} = object
      x: cint
    type Foo2 {.cppNonPod, importcpp: "Foo2", header: "mtlsemulation.h".} = object
      x: cint

    var ctorCalls {.importcpp.}: cint
    var dtorCalls {.importcpp.}: cint
    type Foo3 {.cppNonPod, importcpp: "Foo3", header: "mtlsemulation.h".} = object
      x: cint

    proc sub(i: int) =
      var g1 {.threadvar.}: Foo1
      var g2 {.threadvar.}: Foo2
      var g3 {.threadvar.}: Foo3
      discard g1
      discard g2

      # echo (g3.x, ctorCalls, dtorCalls)
      when compileOption("tlsEmulation"):
        # xxx bug
        discard
      else:
        doAssert g3.x.int == 10 + i
        doAssert ctorCalls == 2
      doAssert dtorCalls == 1
      g3.x.inc

    proc main() =
      doAssert ctorCalls == 0
      doAssert dtorCalls == 0
      block:
        var f3: Foo3
        doAssert f3.x == 10
      doAssert ctorCalls == 1
      doAssert dtorCalls == 1

      for i in 0..<3:
        sub(i)
    main()
