discard """
  targets: "c cpp"
  output: '''
(5, 7)
(1, 2)
'''
"""

# bug #14552: assigning to a `var` field of a tuple
# (the JS backend cannot yield tuples of `var` yet: genAddr: nkHiddenSubConv)
template assign[T](a, b: T) =
  a = b
var x = (5, 6)
iterator returnStuff(): (var (int, int),) =
  yield (x,)
for item in returnStuff():
  assign(item[0], (5, 6))
  item[0] = (5, 7)
echo x

proc main =
  var y = (0, 0)
  iterator mine(): (var (int, int),) =
    yield (y,)
  for item in mine():
    item[0] = (1, 2)
  echo y
main()
