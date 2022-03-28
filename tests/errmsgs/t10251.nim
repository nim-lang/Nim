discard """
  action:reject
  cmd: "nim check $options $file"
  nimout: '''
t10251.nim(19, 23) Error: redefinition of 'goo1'; previous declaration here: t10251.nim(19, 11)
'''
"""

# line 10
type
  Enum1 = enum
    foo, bar, baz
  Enum2 = enum
    foo, bar, baz


type
  Enum3 {.pure.} = enum # fixed (by accident?) in https://github.com/nim-lang/Nim/pull/18263
    goo0, goo1, goo2, goo1
