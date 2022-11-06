discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  outputsub: '''
t12559.nim(15, 36) Error: access field 'x' of nil literal



'''
"""

type T = ref object
  x: int

proc f(arg:static  T) = discard arg.x

f nil
