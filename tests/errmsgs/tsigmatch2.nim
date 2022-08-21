discard """
  cmd: "nim check --showAllMismatches:on --hints:off $file"
  nimout: '''
tsigmatch2.nim(40, 14) Error: type mismatch: got <float64>
but expected one of:
proc foo(args: varargs[string, myproc]): string
  first type mismatch at position: 1
  required type for args: varargs[string]
  but expression '1.2' is of type: float64
proc foo(i: Foo): string
  first type mismatch at position: 1
  required type for i: Foo
  but expression '1.2' is of type: float64

expression: foo(1.2)
tsigmatch2.nim(40, 14) Error: expression '' has no type (or is ambiguous)
tsigmatch2.nim(46, 7) Error: type mismatch: got <int literal(1)>
but expected one of:
proc foo(args: varargs[string, myproc])
  first type mismatch at position: 1
  required type for args: varargs[string]
  but expression '1' is of type: int literal(1)

expression: foo 1
'''
  errormsg: "type mismatch"
"""


# line 30
type Foo = object
block: # issue #13182
  proc myproc(a: int): string = $("myproc", a)
  proc foo(args: varargs[string, myproc]): string = $args

  proc foo(i: Foo): string = "in foo(i)"
  static: doAssert foo(Foo()) == "in foo(i)"
  static: doAssert foo(1) == """["(\"myproc\", 1)"]"""
  doAssert not compiles(foo(1.2))
  discard foo(1.2)

block:
  proc myproc[T](x: T): string =
    let temp = 12.isNil
  proc foo(args: varargs[string, myproc]) = discard
  foo 1
static: echo "done"