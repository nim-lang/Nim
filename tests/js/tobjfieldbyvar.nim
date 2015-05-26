discard """
  output: '''5
'''
"""

# bug #2798

type Inner = object
  value: int

type Outer = object
  i: Inner

proc test(i: var Inner) =
  i.value += 5

var o: Outer
test(o.i)

echo o.i.value
