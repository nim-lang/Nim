discard """
  output: '''compiles'''
"""

# Test that the object type does not need to be resolved at all:

type
  mypackage.Foo = object
  Other = proc (inp: Foo)

  Node = ref object
    external: ptr Foo
    data: string

var x: Node
new(x)
x.data = "compiles"

echo x.data
