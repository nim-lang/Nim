discard """
  output: '''foo 0
bar 0
baz'''
"""

# bug #1641
proc baz() =
  echo "baz"

proc bar(x: int, p: proc()) =
  echo "bar ", x
  p()

proc foo(x: int, p: proc(x: int)) =
  echo "foo ", x
  p(x)

let x = 0
x.foo do(x: int): x.bar do(): baz()
