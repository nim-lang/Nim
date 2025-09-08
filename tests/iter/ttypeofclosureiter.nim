# issue #24859

template u(): int =
  yield 0
  0
iterator s(): int {.closure.} = discard default(typeof(u()))
let _ = s
