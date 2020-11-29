
discard """
  output: '''5
vseq destroy
'''
joinable: false
"""
type
  opt*[T] = object
    case exists: bool
      of true: val: T
      of false: discard

proc some*[T](val: sink T): opt[T] {.inline.} =
  ## Returns an ``opt`` that has the value.
  ## nil is considered as none for reference types
  result = opt[T](exists: true, val: val)

proc none*(T: typedesc): opt[T] {.inline.} =
  ## Returns an ``opt`` for this type that has no value.
  # the default is the none type
  discard

proc none*[T]: opt[T] {.inline.} =
  ## Alias for ``none(T)``.
  none(T)

proc unsafeGet*[T](self: opt[T]): lent T {.inline.} =
  ## Returns the value of a ``some``. Behavior is undefined for ``none``.
  self.val

type
  VSeq*[T] = object
    len: int
    data: ptr UncheckedArray[T]

proc `=destroy`*[T](m: var VSeq[T]) {.inline.} =
  if m.data != nil:
    echo "vseq destroy"
    dealloc(m.data)
    m.data = nil

proc `=`*[T](m: var VSeq[T], m2: VSeq[T]) {.error.}

proc `=sink`*[T](m: var VSeq[T], m2: VSeq[T]) {.inline.} =
  if m.data != m2.data:
    `=destroy`(m)
  m.len = m2.len
  m.data = m2.data

proc newVSeq*[T](len: int): VSeq[T] =
  ## Only support sequence creation from scalar size because creation from
  ## vetorized size can't reproduce the original scalar size
  result.len = len
  if len > 0:
    result.data = cast[ptr UncheckedArray[T]](alloc(sizeof(T) * len))

let x = some newVSeq[float](5)
echo x.unsafeGet.len
let y = none(VSeq[float])

