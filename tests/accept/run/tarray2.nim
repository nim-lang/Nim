discard """
  file: "tarray2.nim"
  output: "[16, 25, 36]"
"""
# simple check for one dimensional arrays

type
  TMyArray = array[0..2, int]

proc mul(a, b: TMyarray): TMyArray =
  result = a
  for i in 0..len(a)-1:
    result[i] = a[i] * b[i]

var
  x, y, z: TMyArray
 
x = [ 4, 5, 6 ]
y = x
echo repr(mul(x, y))

#OUT [16, 25, 36]


