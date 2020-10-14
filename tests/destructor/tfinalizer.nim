discard """
  cmd: "nim c --gc:arc $file"
  output: '''Foo(field: "Dick Laurent", k: ka, x: 0.0)
Nobody is dead
Dick Laurent is dead'''
"""

type
  Kind = enum
    ka, kb
  Foo = ref object
    field: string
    case k: Kind
    of ka: x: float
    of kb: discard

#var x = Foo(field: "lovely")
proc finalizer(x: Foo) =
  echo x.field, " is dead"

var x: Foo
new(x, finalizer)
x.field = "Dick Laurent"
# reference to a great movie. If you haven't seen it, highly recommended.

echo repr x

# bug #13112: bind the same finalizer multiple times:
var xx: Foo
new(xx, finalizer)
xx.field = "Nobody"
