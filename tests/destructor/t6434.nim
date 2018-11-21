discard """
  exitcode: 0
  output: '''assingment
assingment
assingment
assingment
'''
"""

type
  Foo* = object
    boo: int

proc `=`(dest: var Foo, src: Foo) =
  debugEcho "assingment"

proc test(): auto =
  var a,b : Foo
  return (a, b, Foo(boo: 5))

var (a, b, _) = test()