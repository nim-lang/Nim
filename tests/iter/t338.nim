discard """
  output: '''0
1
2
3
4
'''
"""

proc moo(): iterator (): int =
  iterator fooGen: int {.closure.} =
    while true:
      yield result
      result.inc
  return fooGen

var foo = moo()

for i in 0 .. 4:
  echo foo()
