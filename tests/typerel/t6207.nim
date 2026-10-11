discard """
  output: '''
set {foo1}
set {}
seq 0
'''
"""

# bug #6207: empty containers passed to a type class
type Foo = enum
  foo1

proc bar(f1, f2: set[Foo] | Foo) =
  echo "set ", f2

bar({foo1}, {foo1})
bar({foo1}, {})

proc baz(x: seq[int] | int) =
  when x is seq: echo "seq ", x.len
  else: echo "int"

baz(@[])
