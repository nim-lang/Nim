discard """
  file: "tstaticparams.nim"
  output: "abracadabra\ntest\n3"
"""

type 
  TFoo[T; Val: expr[string]] = object
    data: array[4, T]

  TBar[T; I: expr[int]] = object
    data: array[I, T]

  TA1[T; I: expr[int]] = array[I, T]
  TA2[T; I: expr[int]] = array[0..I, T]
  TA3[T; I: expr[int]] = array[I-1, T]

proc takeFoo(x: TFoo) =
  echo "abracadabra"
  echo TFoo.Val

var x: TFoo[int, "test"]
takeFoo(x)

var y: TBar[float, 4]
echo high(y.data)

var
  t1: TA1
  t2: TA2
  t3: TA3

