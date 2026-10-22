discard """
  cmd: "nim check --parsem:on --hints:off $file"
  nimout: '''tnestedprocs_parsem.nim(44, 8) Error: 'inner' can have side effects
> tnestedprocs_parsem.nim(46, 13) Hint: 'inner' calls `.sideEffect` 'outer6'
>> tnestedprocs_parsem.nim(43, 6) Hint: 'outer6' called by 'inner'
>>> tnestedprocs_parsem.nim(49, 3) Hint: 'outer6' calls `.sideEffect` 'echo'
'''
  errormsg: "type mismatch: got <proc ()> but expected 'proc (){.closure, noSideEffect.}'"
"""
# `--parsem:on` variant of tests/effects/tnestedprocs: `outer2` and its
# `inner` only call each other, so the cycle they form has no side effect and
# `inner`'s `.noSideEffect` holds. Without the switch `inner` is checked while
# `outer2`'s effects are still unknown, which counts as a side effect. `outer6`
# does echo, and the error says so.
{.experimental: "strictEffects".}
proc outer {.noSideEffect.} =
  proc inner(p: int) =
    if p == 0:
      outer()

  inner(4)

outer()

proc outer2 =
  proc inner(p: int) {.noSideEffect.} =
    if p == 0:
      outer2()

  inner(4)

outer2()

proc outer3(p: int) {.noSideEffect.} =
  proc inner(p: int) {.noSideEffect.} =
    if p == 0:
      p.outer3()

  inner(4)

outer3(5)

proc outer6 =
  proc inner(p: int) {.noSideEffect.} =
    if p == 0:
      outer6()

  inner(4)
  echo "bad"

outer6()


proc outer4 =
  proc inner(p: int) {.noSideEffect.} =
    if p == 0:
      let x: proc () {.noSideEffect.} = outer4
      x()

  inner(4)

outer4()
