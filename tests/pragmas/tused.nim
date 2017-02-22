discard """
  output: '''8'''
"""

template implementArithOps(T) =
  proc echoAdd(a, b: T) {.used.} =
    echo a + b
  proc echoSub(a, b: T) {.used.} =
    echo a - b

# no warning produced for the unused 'echoSub'
implementArithOps(int)
echoAdd 3, 5
