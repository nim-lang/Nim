discard """
cmd: "nim check --hints:off $file"
action: reject
nimout: '''
t21863.nim(25, 18) Error: redefinition of 'A'; previous declaration here: t21863.nim(24, 18)
t21863.nim(28, 16) Error: undeclared field: 'A'
  found 'A' [enumField declared in t21863.nim(25, 18)]
t21863.nim(28, 16) Error: undeclared field: '.'
t21863.nim(28, 16) Error: undeclared field: '.'
t21863.nim(28, 16) Error: expression '' has no type (or is ambiguous)
'''
"""









block:
  type
    EnumA = enum A, B
    EnumB = enum A
    EnumC = enum C

  discard EnumC.A
