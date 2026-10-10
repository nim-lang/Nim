discard """
  output: '''
3
8
'''
"""

# bug #25229
proc f(x: SomeFloat): int {.exportc.} = int(x) + 1
echo f(2.0)

proc g(x: int): int {.exportc.} = x * 2
echo g(4)
