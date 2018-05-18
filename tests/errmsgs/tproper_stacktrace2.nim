discard """
  outputsub: '''tproper_stacktrace2.nim(20) main'''
  exitcode: 1
"""

proc returnsNil(): ref int = return nil

iterator fields*(a, b: int): int =
  if a == b:
    for f in a..b:
      yield f
  else:
    for f in a..b:
      yield f

proc main(): string =
  result = ""
  for i in fields(0, 1):
    let x = returnsNil()
    result &= "string literal " & $x[]

echo main()
