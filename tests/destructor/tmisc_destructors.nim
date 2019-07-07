discard """
  output: '''@[0]
@[1]
@[2]
@[3]'''
  joinable: false
"""

# bug #6434

type
  Foo* = object
    boo: int

var move_counter = 0
var assign_counter = 0

proc `=move`(dest, src: var Foo) =
  move_counter.inc

proc `=`(dest: var Foo, src: Foo) =
  assign_counter.inc

proc test(): auto =
  var a,b : Foo
  return (a, b, Foo(boo: 5))

var (a, b, _) = test()

doAssert assign_counter == 0
doAssert sink_counter == 12 # + 3 because of the conservative tuple unpacking transformation

# bug #11510
proc main =
  for i in 0 ..< 4:
    var buffer: seq[int] # = @[] # uncomment to make it work
    # var buffer: string # also this is broken
    buffer.add i
    echo buffer

main()
