discard """
  output: '''10000000
10000000
10000000'''
"""

# bug #17085

proc init(): string =
  for a in 0..<10000000:
    result.add 'c'

proc f() =
  var a {.global.} = init()
  var b {.global.} = init()
  var c {.global.} = init()

  echo a.len
  echo b.len
  echo c.len

f()
