discard """
  output: '''compiles'''
  joinable: false
"""

# importing both usefoo and usefoo2 at the same time causes a bug. Importing only one is OK.

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
