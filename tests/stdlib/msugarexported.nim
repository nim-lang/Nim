import sugar

template defineX(y) =
  let x {.inject.} = y

exported defineX(3)

template bar(T, body) {.dirty.} =
  proc foo(x: T): T =
    body

exported:
  bar int:
    x + 1
  bar string:
    x & '.'

exported:
  type Foo = object
    field: int

proc macroPragmaProc(): bool {.exported.} = true
