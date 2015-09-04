discard """
  file: "tarray2.nim"
  output: "[4, 5, 6]\n\n[16, 25, 36]\n\n[16, 25, 36]"
"""
# simple check for one dimensional arrays

type
  TMyArray = array[0..2, int]

  TObj = object
    arr: TMyarray

proc mul(a, b: TMyarray): TMyArray =
  result = a
  for i in 0..len(a)-1:
    result[i] = a[i] * b[i]

var
  x, y: TMyArray
  o: TObj

proc varArr1(x: var TMyArray): var TMyArray = x
proc varArr2(x: var TObj): var TMyArray = x.arr

x = [ 4, 5, 6 ]
echo repr(varArr1(x))

y = x
echo repr(mul(x, y))

o.arr = mul(x, y)
echo repr(varArr2(o))

#OUT [16, 25, 36]


