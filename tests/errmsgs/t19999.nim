discard """
errormsg: "'enum' is not a concrete type"
line: 16
"""

type Action = enum
  Fire
  Jump

proc test1[T:enum](keys: varargs[T]) = 
  for s in keys:
    doAssert s is Action

test1(Fire,Jump)

proc test2(keys: varargs[enum]) = 
  for s in keys:
    doAssert s is Action

test2(Fire,Jump)