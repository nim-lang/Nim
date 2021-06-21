
discard """
   output: '''5.0 10.0
=destroy
=destroy
'''
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


#-------------------------------------------------------------
type
  MyObject* = object
    len*: int
    amount: UncheckedArray[float]

  MyObjPtr* = ptr MyObject

  MyObjContainer* {.byref.} = object
    size1: int
    size2: int
    data: ptr UncheckedArray[MyObjPtr]

 
proc size1*(m: MyObjContainer): int {.inline.} = m.size1
proc size2*(m: MyObjContainer): int {.inline.} = m.size2

proc allocateMyObjPtr(size2: int): MyObjPtr =
  cast[MyObjPtr](allocShared(sizeof(MyObject) + sizeof(float) * size2.int))

proc `=destroy`*(m: var MyObjContainer) {.inline.} =
  if m.data != nil:
    for i in 0..<m.size1:
      if m.data[i] != nil:
        deallocShared(m.data[i])
        m.data[i] = nil
    deallocShared(m.data)
    echo "=destroy"
    m.data = nil

proc `=sink`*(m: var MyObjContainer, m2: MyObjContainer) {.inline.} =
  if m.data != m2.data:
    `=destroy`(m)
  m.size1 = m2.size1
  m.size2 = m2.size2  
  m.data = m2.data


proc `=`*(m: var MyObjContainer, m2: MyObjContainer) {.error.}
  ## non copyable

func newMyObjContainer*(size2: Natural): MyObjContainer =
  result.size2 = size2

proc push(m: var MyObjContainer, cf: MyObjPtr) =
  ## Add MyObjPtr to MyObjContainer, shallow copy
  m.size1.inc
  m.data = cast[ptr UncheckedArray[MyObjPtr]](reallocShared(m.data, m.size1 * sizeof(MyObjPtr)))
  m.data[m.size1 - 1] = cf

 
proc add*(m: var MyObjContainer, amount: float) =
  assert m.size2 > 0, "MyObjContainer is not initialized, use newMyObjContainer() to initialize object before use"
  let cf = allocateMyObjPtr(m.size2)
  for i in 0..<m.size2:
    cf.amount[i.int] = amount

  m.push(cf)

proc add*(dest: var MyObjContainer, src: sink MyObjContainer) =
  # merge containers

  for i in 0..<src.size1:
    dest.push src.data[i]
    src.data[i] = nil

 
proc test = 
  var cf1 = newMyObjContainer(100)
  cf1.add(1)
  cf1.add(2)

  var cf3 = newMyObjContainer(100)
  cf3.add(2)
  cf3.add(3)

  cf1.add(cf3)

test()
