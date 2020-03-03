discard """
  output: '''@[(x: 3, y: 4)]'''
"""

type
  mypackage.Foo = object
  Other = proc (inp: Foo)

import definefoo

# after this import, Foo is a completely resolved type, so
# we can create a sequence of it:
var s: seq[Foo] = @[]

s.add Foo(x: 3, y: 4)
echo s
