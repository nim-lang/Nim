discard """
  output: '''ABCDC
1
14
ok'''
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