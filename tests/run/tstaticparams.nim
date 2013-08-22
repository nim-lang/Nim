discard """
  file: "tstaticparams.nim"
  output: "abracadabra\ntest\n3"
"""

type 
  TFoo[T; Val: expr[string]] = object
    data: array[4, T]

  TBar[T; I: expr[int]] = object
    data: array[I, T]

proc takeFoo(x: TFoo) =
  echo "abracadabra"
  echo TFoo.Val

var x: TFoo[int, "test"]
takeFoo(x)

var y: TBar[float, 4]
echo high(y.data)

