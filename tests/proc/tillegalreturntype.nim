discard """
  cmd: "nim check $file"
  errmsg: ""
  nimout: '''
tillegalreturntype.nim(11, 11) Error: return type 'typed' is only valid for macros and templates
tillegalreturntype.nim(14, 11) Error: return type 'untyped' is only valid for macros and templates
tillegalreturntype.nim(17, 21) Error: return type 'typedesc' is only valid for macros and templates
'''
"""

proc x(): typed =
  discard

proc y(): untyped =
  discard

proc foo(arg: int): typedesc =
  return float

foo(1)
