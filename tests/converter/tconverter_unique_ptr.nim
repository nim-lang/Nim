
discard """
  file: "tconverter_unique_ptr.nim"
  targets: "c cpp"
  output: '''5
2.0 5
'''
"""

## Bugs 9698 and 9699

type
  UniquePtr*[T] = object
    ## non copyable pointer to object T, exclusive ownership of the object is assumed
    val: ptr T

  MyLen* = distinct int

  MySeq* = object
    ## Vectorized matrix
    len: MyLen  # scalar size
    data: ptr UncheckedArray[float]

proc `$`(x: MyLen): string {.borrow.}

proc `=destroy`*(m: var MySeq) {.inline.} =
  if m.data != nil:
    deallocShared(m.data)
    m.data = nil

proc `=`*(m: var MySeq, m2: MySeq) =
  if m.data == m2.data: return
  if m.data != nil:
    `=destroy`(m)

  m.len = m2.len
  let bytes = m.len.int * sizeof(float) 
  if bytes > 0:
    m.data = cast[ptr UncheckedArray[float]](allocShared(bytes))
    copyMem(m.data, m2.data, bytes)

proc `=sink`*(m: var MySeq, m2: MySeq) {.inline.} =
  if m.data != m2.data:
    if m.data != nil:
      `=destroy`(m)
    m.len = m2.len
    m.data = m2.data

proc len*(m: MySeq): MyLen {.inline.} = m.len

proc lenx*(m: var MySeq): MyLen {.inline.} = m.len


proc `[]`*(m: MySeq; i: MyLen): float {.inline.} =
  m.data[i.int]

proc `[]=`*(m: var MySeq; i: MyLen, val: float) {.inline.} =
  m.data[i.int] = val

proc setTo(s: var MySeq, val: float) = 
  for i in 0..<s.len.int:
    s.data[i] = val

proc newMySeq*(size: int, initial_value = 0.0): MySeq =
  result.len = size.MyLen
  if size > 0:
    result.data = cast[ptr UncheckedArray[float]](createShared(float, size))

  result.setTo(initial_value)

converter literalToLen*(x: int{lit}): MyLen =
  x.MyLen


#-------------------------------------------------------------
# Unique pointer implementation
#-------------------------------------------------------------

proc `=destroy`*[T](p: var UniquePtr[T]) =
  if p.val != nil:
    `=destroy`(p.val[])
    dealloc(p.val)
    p.val = nil

proc `=`*[T](dest: var UniquePtr[T], src: UniquePtr[T]) {.error.}

proc `=sink`*[T](dest: var UniquePtr[T], src: UniquePtr[T]) {.inline.} =
  if dest.val != nil and dest.val != src.val:
    `=destroy`(dest)
  dest.val = src.val

proc newUniquePtr*[T](val: sink T): UniquePtr[T] =
  result.val = cast[type(result.val)](alloc(sizeof(result.val[])))
  reset(result.val[])
  result.val[] = val

converter convertPtrToObj*[T](p: UniquePtr[T]): var T =
  result = p.val[]


var pu = newUniquePtr(newMySeq(5, 1.0))
echo pu.len

pu[0] = 2.0
echo pu[0], " ", pu.lenx


