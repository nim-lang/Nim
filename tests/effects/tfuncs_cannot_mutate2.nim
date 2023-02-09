discard """
  errormsg: "cannot mutate location x[0].a within a strict func"
  line: 12
"""

{.experimental: "strictFuncs".}

func copy[T](x: var openArray[T]; y: openArray[T]) =
  for i in 0..high(x):
    x[i] = y[i]

  x[0].a = nil

type
  R = ref object
    a, b: R
    data: string

proc main =
  var a, b: array[3, R]
  b = [R(data: "a"), R(data: "b"), R(data: "c")]
  copy a, b

main()
