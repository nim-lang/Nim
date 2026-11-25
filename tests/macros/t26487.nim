discard """
  output: '''
1
2
'''
"""

# bug #26487: "has to be used" after a typed macro returns `while true: break`
macro passthrough(n: typed): untyped = n

proc f(): int =
  passthrough:
    while true:
      break
  1

proc g(x: bool): int =
  passthrough:
    while true:
      if x: break
      else: raise newException(ValueError, "x")
  2

echo f()
echo g(true)
