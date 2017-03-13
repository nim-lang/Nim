discard """
  file: "tbasicenum.nim"
  output: "ABCDC"
"""

type
  MyEnum = enum
    A,B,C,D
# trick the optimizer with an seq:
var x = @[A,B,C,D]
echo x[0],x[1],x[2],x[3],MyEnum(2)