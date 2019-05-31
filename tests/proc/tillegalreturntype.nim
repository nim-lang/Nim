discard """
  cmd: "nim check $file"
  errmsg: ""
  nimout: '''tillegalreturntype.nim(8, 11) Error: return type 'typed' is only valid for macros and templates
tillegalreturntype.nim(11, 11) Error: return type 'untyped' is only valid for macros and templates'''
"""

proc x(): typed =
  discard

proc y(): untyped =
  discard
