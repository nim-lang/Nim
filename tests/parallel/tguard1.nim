discard """
output: "90"
"""

type
  ProtectedCounter[T] = object
    i {.guard: L.}: T
    L: int

var
  c: ProtectedCounter[int]

c.i = 89

template atomicRead(L, x): untyped =
  {.locks: [L].}:
    x

proc main =
  {.locks: [c.L].}:
    inc c.i
    discard
  echo(atomicRead(c.L, c.i))

main()
