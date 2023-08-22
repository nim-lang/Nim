discard """
  nimout: '''
compile start
tused.nim(17, 8) Hint: 'echoSub' is declared but not used [XDeclaredButNotUsed]
compile end'''
  output: "8\n8"
  joinable: false
"""

# not joinable because paths in nimout differ when imported
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

# issue #9896
type
  MyEnum {.used.} = enum
    Val1, Val2, Val3


static:
  echo "compile end"
