discard """
  output: '''(x: 0, y: 0)
(x: 5, y: 0)
@[(x: "2", y: 4), (x: "4", y: 5), (x: "4", y: 5)]
@[(a: "3", b: 3), (a: "1", b: 1), (a: "2", b: 2)]
'''
"""

# bug #4139

type
  TestO = object
    x, y: int

proc onLoad() =
  var test: seq[TestO] = @[]
  var foo = TestO(x: 0, y: 0)
  test.add(foo)
  foo.x = 5
  echo(test[0])
  echo foo

onLoad()

# 'setLen' bug (part of bug #5933)
type MyObj = object
  x: cstring
  y: int

proc foo(x: var seq[MyObj]) =
  let L = x.len
  x.setLen L + 1
  x[L] = x[1]

var s = @[MyObj(x: "2", y: 4), MyObj(x: "4", y: 5)]
foo(s)
echo s

# bug  #5933
import sequtils

type
  Test = object
    a: cstring
    b: int

var test = @[Test(a: "1", b: 1), Test(a: "2", b: 2)]

test.insert(@[Test(a: "3", b: 3)], 0)

echo test
