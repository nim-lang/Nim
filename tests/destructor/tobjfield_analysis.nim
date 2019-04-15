discard """
  output: '''works'''
"""

type
  MyVal = object
    f: ptr float

proc `=destroy`(x: var MyVal) =
  if x.f != nil:
    dealloc(x.f)

proc `=sink`(x1: var MyVal, x2: Myval) =
  if x1.f != x2.f:
    `=destroy`(x1)
    x1.f = x2.f

proc `=`(x1: var MyVal, x2: Myval) {.error.}

proc newVal(x: float): MyVal =
  result.f = create(float)
  result.f[] = x

proc sinkMe(x: sink MyVal) =
  discard

proc main =
  var y = (newVal(3.0), newVal(4.0))

  sinkMe y[0]
  sinkMe y[1]
  echo "works"

main()

