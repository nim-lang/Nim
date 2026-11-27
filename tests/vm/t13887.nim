discard """
  output: "ok"
"""

# bug #13887
static:
  var x = 5
  var y = addr(x)
  y[] += 10
  doAssert x == y[]
template fun() =
  var s = @[10,11,12]
  let z = s[0].addr
  z[] = 100
  doAssert s[0] == 100
static: fun()
template fun3() =
  var s = @[10.1,11.2,12.3]
  let z = s[0].addr
  echo cast[int](z) != 0
static: fun3()
echo "ok"
