discard """
  errormsg: '''nil literal access'''
  line: 11
"""



type T = ref object
  x: int

proc f(arg:static  T) = discard arg.x

f nil
