discard """
   output: '''abcsuffix
xyzsuffix'''
  cmd: '''nim c --gc:arc $file'''
"""

proc select(cond: bool; a, b: sink string): string =
  if cond:
    result = a # moves a into result
  else:
    result = b # moves b into result

proc test(param: string; cond: bool) =
  var x = "abc" & param
  var y = "xyz" & param

  # possible self-assignment:
  x = select(cond, x, y)

  echo x
  # 'select' must communicate what parameter has been
  # consumed. We cannot simply generate:
  # (select(...); wasMoved(x); wasMoved(y))

test("suffix", true)
test("suffix", false)
