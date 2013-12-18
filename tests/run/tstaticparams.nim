discard """
  file: "tstaticparams.nim"
  output: "abracadabra\ntest\n3"
"""

type 
  TFoo[T; Val: static[string]] = object
    data: array[4, T]

  TBar[T; I: static[int]] = object
    data: array[I, T]

  #TA1[T; I: static[int]] = array[I, T]
  #TA2[T; I: static[int]] = array[0..I, T]
  TA3[T; I: static[int]] = array[I-1, T]

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

