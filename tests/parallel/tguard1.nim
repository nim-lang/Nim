discard """
output: "90"
"""


when false:
  template lock(a, b: ptr Lock; body: stmt) =
    if cast[ByteAddress](a) < cast[ByteAddress](b):
      pthread_mutex_lock(a)
      pthread_mutex_lock(b)
    else:
      pthread_mutex_lock(b)
      pthread_mutex_lock(a)
    {.locks: [a, b].}:
      try:
        body
      finally:
        pthread_mutex_unlock(a)
        pthread_mutex_unlock(b)

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
