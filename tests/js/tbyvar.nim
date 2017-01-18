discard """
  output: '''foo 12
bar 12
2
foo 12
bar 12
2
'''
"""

# bug #1489
proc foo(x: int) = echo "foo ", x
proc bar(y: var int) = echo "bar ", y

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

# Test: pass var seq to var openarray
var s = @[2, 1]
proc foo(a: var openarray[int]) = a[0] = 123

proc bar(s: var seq[int], a: int) =
  doAssert(a == 5)
  foo(s)
s.bar(5)
doAssert(s == @[123, 1])

import tables
block: # Test get addr of byvar return value
  var t = initTable[string, int]()
  t["hi"] = 5
  let a = addr t["hi"]
  a[] = 10
  doAssert(t["hi"] == 10)

block: # Test var arg inside case expression. #5244
  proc foo(a: var string) =
    a = case a
    of "a": "error"
    of "b": "error"
    else: a
  var a = "ok"
  foo(a)
  doAssert(a == "ok")
