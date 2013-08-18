discard """
  file: "tstaticparams.nim"
  output: "abracadabra\ntest"
"""

type 
  TFoo[T; Val: expr[string]] = object
    data: array[4, T]

proc takeFoo(x: TFoo) =
  echo "abracadabra"
  echo TFoo.Val

var x: TFoo[int, "test"]

takeFoo(x)

