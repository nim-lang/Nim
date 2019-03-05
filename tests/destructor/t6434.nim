discard """
  exitcode: 0
  output: ""
  joinable: false
"""

type
  Foo* = object
    boo: int

var sink_counter = 0
var assign_counter = 0

proc `=sink`(dest: var Foo, src: Foo) =
  sink_counter.inc

proc `=`(dest: var Foo, src: Foo) =
  assign_counter.inc

proc test(): auto =
  var a,b : Foo
  return (a, b, Foo(boo: 5))

var (a, b, _) = test()

doAssert: assign_counter == 0
doAssert: sink_counter == 9