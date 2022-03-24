discard """
  output: '''ABCDC
1
14
ok
1'''
"""

type
  MyEnum = enum
    A,B,C,D
# trick the optimizer with an seq:
var x = @[A,B,C,D]
echo x[0],x[1],x[2],x[3],MyEnum(2)

# bug #10651

var xa: seq[int]
var ya = @[1,2]
xa &= ya
echo xa[0]

proc test =
  var yup: seq[int]
  try:
    yup.add 14
    echo yup.pop
  finally:
    discard

test()

when true:
  var a: seq[int]

  a.setLen(0)

  echo "ok"

# bug #10697
proc test2 =
  var val = uint16(0)
  var i = 0
  if i < 2:
    val += uint16(1)
  echo int(val)

test2()


var someGlobal = default(array[5, int])
for x in someGlobal: doAssert(x == 0)

proc tdefault =
  var x = default(int)
  doAssert(x == 0)
  proc inner(v: openArray[string]) =
    doAssert(v.len == 0)

  inner(default(seq[string]))

tdefault()
