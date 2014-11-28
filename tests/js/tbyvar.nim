discard """
  output: '''foo 12
bar 12
2
foo 12
bar 12
2'''
"""

# bug #1489
proc foo(x: int) = echo "foo: ", x
proc bar(y: var int) = echo "bar: ", y

var x = 12
foo(x)
bar(x)

# bug #1490
var y = 1
y *= 2
echo y

proc main =
  var x = 12
  foo(x)
  bar(x)

  var y = 1
  y *= 2
  echo y

main()
