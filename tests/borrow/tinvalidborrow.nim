discard """
  cmd: "nim check --hints:off --warnings:off $file"
  action: "reject"
  nimout:'''
tinvalidborrow.nim(18, 3) Error: only a 'distinct' type can borrow `.`
tinvalidborrow.nim(19, 3) Error: only a 'distinct' type can borrow `.`
tinvalidborrow.nim(20, 1) Error: no symbol to borrow from found
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
