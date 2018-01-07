discard """
  output: '''(foo: 38, other: "string here")
43
100
90'''
"""

type
  Base = ref object of RootObj
  Foo {.partial.} = ref object of Base

proc my(f: Foo) =
  #var f.next = f
  let f.foo = 38
  let f.other = "string here"
  echo f[]
  echo f.foo + 5

var g: Foo
new(g)
my(g)

type
  FooTask {.partial.} = ref object of RootObj

proc foo(t: FooTask) {.liftLocals: t.} =
  var x = 90
  if true:
    var x = 10
    while x < 100:
      inc x
    echo x
  echo x

foo(FooTask())
