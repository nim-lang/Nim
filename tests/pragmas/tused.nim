discard """
  nimout: '''
compile start
tused.nim(15, 8) Hint: 'tused.echoSub(a: int, b: int)[declared in tused.nim(15, 7)]' is declared but not used [XDeclaredButNotUsed]
compile end'''
  output: "8\n8"
"""

static:
  echo "compile start"

template implementArithOpsOld(T) =
  proc echoAdd(a, b: T) =
    echo a + b
  proc echoSub(a, b: T) =
    echo a - b

template implementArithOpsNew(T) =
  proc echoAdd(a, b: T) {.used.} =
    echo a + b
  proc echoSub(a, b: T) {.used.} =
    echo a - b

block:
  # should produce warning for the unused 'echoSub'
  implementArithOpsOld(int)
  echoAdd 3, 5

block:
  # no warning produced for the unused 'echoSub'
  implementArithOpsNew(int)
  echoAdd 3, 5

type
  MyEnum {.used.} = enum
    Val1, Val2, Val3


static:
  echo "compile end"
