block global:
  proc getState(): int =
    var state0 {.global.}: int
    inc state0
    result = state0

  for i in 0 ..< 3:
    doAssert getState() == i + 1

  for i in 0 ..< 3:
    once:
      doAssert i == 0


block threadvar:
  proc getThreadState0(): int =
    var state0 {.threadvar.}: int
    inc state0
    result = state0

  for i in 0 ..< 3:
    doAssert getThreadState0() == i + 1

  proc getThreadState1(): int =
    var state1 {.threadvar.}: int
    inc state1
    result = state1

  for i in 0 ..< 3:
    doAssert getThreadState1() == i + 1
