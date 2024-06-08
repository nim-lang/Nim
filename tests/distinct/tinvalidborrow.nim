discard """
  cmd: "nim check --hints:off --warnings:off $file"
  action: "reject"
  nimout:'''
tinvalidborrow.nim(25, 3) Error: only a 'distinct' type can borrow `.`
tinvalidborrow.nim(26, 3) Error: only a 'distinct' type can borrow `.`
tinvalidborrow.nim(27, 1) Error: borrow proc without distinct type parameter is meaningless
tinvalidborrow.nim(36, 1) Error: borrow with generic parameter is not supported
tinvalidborrow.nim(41, 1) Error: borrow from proc return type mismatch: 'T'
tinvalidborrow.nim(42, 1) Error: borrow from '[]=' is not supported
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
