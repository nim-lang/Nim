discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout: '''
tcase_stmt.nim(22, 7) Error: selector must be of an ordinal type, float or string
tcase_stmt.nim(28, 6) Error: selector must be of an ordinal type, float or string







'''
"""



# bug #19682
type A = object

case A()
else:
  discard

# bug #20283

case @[]
else: discard
