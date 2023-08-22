discard """
  output: '''5
14
0'''
"""

iterator count[T](x: T, skip: bool): int {.closure.} =
  if skip: return x+10
  else: yield x+1

  if skip: return x+10
  else: yield x+2

proc takeProc[T](x: iterator (x: T, skip: bool): int) =
  echo x(4, false)
  echo x(4, true)
  echo x(4, false)

takeProc(count[int])

