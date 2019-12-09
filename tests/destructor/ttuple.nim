
discard """
   output: '''5.0 10.0'''
"""

type
  MyOpt[T] = object
    case has: bool:
      of true: val: T
      of false: nil

  MyVal = object
    f: ptr float

proc `=destroy`(x: var MyVal) =
  if x.f != nil:
    dealloc(x.f)

proc `=sink`(x1: var MyVal, x2: Myval) =
  if x1.f != x2.f:
    `=destroy`(x1)
    x1.f = x2.f

proc `=`(x1: var MyVal, x2: Myval) =
  if x1.f != x2.f:
    `=destroy`(x1)
    x1.f = create(float)
    x1.f[] = x2.f[]

proc newVal(x: float): MyVal =
  result.f = create(float)
  result.f[] = x

template getIt[T, R](self: MyOpt[T], body: untyped, default: R): R =
  if self.has:
    template it: untyped {.inject.} = self.val
    body
  else:
    default

proc myproc(h: MyOpt[float]) =
  let (a, b) = h.getIt((newVal(it), newVal(it * 2)), (newVal(1.0), newVal(1.0)))
  echo a.f[], " ", b.f[]

let h = MyOpt[float](has: true, val: 5.0)
myproc(h)


