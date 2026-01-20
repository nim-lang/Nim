discard """
  cmd: "nim check --hints:off --warnings:off $file"
  action: "reject"
  nimout:'''
tinvalidborrow.nim(25, 21) Error: a type can only borrow `.` for now
tinvalidborrow.nim(23, 3) Error: only a 'distinct' type can borrow `.`
tinvalidborrow.nim(24, 3) Error: only a 'distinct' type can borrow `.`
tinvalidborrow.nim(26, 1) Error: borrow proc without distinct type parameter is meaningless
'''
"""





# bug #516

type
  TAtom = culong
  Test {.borrow:`.`.} = distinct int
  Foo[T] = object
    a: int
  Bar[T] {.borrow:`.`.} = Foo[T]
  OtherFoo {.borrow:`.`.} = Foo[int]
  BadBorrow {.borrow:`[]`.} = distinct seq[int]
proc `==`*(a, b: TAtom): bool {.borrow.}

var
  d, e: TAtom

discard( $(d == e) )

# issue #4121
type HeapQueue[T] = distinct seq[T]
proc len*[T](h: HeapQueue[T]): int {.borrow.}

# issue #3564
type vec4[T] = distinct array[4, float32]

proc `[]`(v: vec4, i: int): float32 {.borrow.}
proc `[]=`(v: vec4, i: int, va: float32) {.borrow.}
