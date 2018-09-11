discard """
cmd: "nim check $file"
errormsg: "the 'in' modifier can be used only with imported types"
nimout: '''
tinvalidinout.nim(14, 7) Error: the 'out' modifier can be used only with imported types
tinvalidinout.nim(17, 9) Error: the 'in' modifier can be used only with imported types
tinvalidinout.nim(18, 9) Error: the 'in' modifier can be used only with imported types
'''
"""

type
  Foo {.header: "foo.h", importcpp.} [in T] = object

  Bar[out X] = object
    x: int

proc f1[in T](x: T) = discard
proc f2[in T](x: T) {.importc: "f", header: "foo.h"}

var
  f: Foo[int]
  b: Bar[string]

f1 f
f2 b

