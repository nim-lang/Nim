discard """
  cmd: "nim check --hints:off $file"
  nimout: '''tnestedprocs.nim(27, 8) Error: 'inner' can have side effects
> tnestedprocs.nim(29, 13) Hint: 'inner' calls `.sideEffect` 'outer2'
>> tnestedprocs.nim(26, 6) Hint: 'outer2' called by 'inner'

tnestedprocs.nim(45, 8) Error: 'inner' can have side effects
> tnestedprocs.nim(47, 13) Hint: 'inner' calls `.sideEffect` 'outer6'
>> tnestedprocs.nim(44, 6) Hint: 'outer6' called by 'inner'

tnestedprocs.nim(58, 41) Error: type mismatch: got <proc ()> but expected 'proc (){.closure, noSideEffect.}'
  Pragma mismatch: got '{..}', but expected '{.noSideEffect.}'.
'''
  errormsg: "type mismatch: got <proc ()> but expected 'proc (){.closure, noSideEffect.}'"
"""
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
