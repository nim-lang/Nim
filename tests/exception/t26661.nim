discard """
  matrix: "--mm:orc; --mm:arc"
  output: '''
caught IOError (OK)
caught IOError (OK)
caught IOError (OK)
'''
"""

# bug #26661: a `try/except` in `=destroy` caught the exception that was
# already propagating through the hook (C backend, `--exceptions:goto`).

type Obj = object
  p: int

var destroyed = 0

proc mayRaise(x: int) {.raises: [ValueError].} =
  if x == 999: raise newException(ValueError, "x")

proc `=destroy`(o: Obj) {.raises: [].} =
  try:
    mayRaise(o.p)
    inc destroyed
  except CatchableError:
    discard

proc f(n: int): seq[Obj] =
  result = @[Obj(p: n)]
  if n > 0: raise newException(IOError, "boom")

proc g(n: int): seq[Obj] =
  result = @[Obj(p: 1)]
  result = f(n) # reassignment from a call

proc h(n: int): int =
  let s = g(n)
  s.len

try:
  echo "returned normally: ", h(1), " (LOST)"
except IOError:
  echo "caught IOError (OK)"

# the hook has no `raises` annotation
type Obj2 = object
  p: int

proc `=destroy`(o: Obj2) =
  try:
    mayRaise(o.p)
  except CatchableError:
    discard

proc f2(n: int): seq[Obj2] =
  result = @[Obj2(p: n)]
  if n > 0: raise newException(IOError, "boom")

proc g2(n: int): seq[Obj2] =
  result = @[Obj2(p: 1)]
  result = f2(n)

try:
  echo "returned normally: ", g2(1).len, " (LOST)"
except IOError:
  echo "caught IOError (OK)"

# the hook handles an exception of its own
type Obj3 = object
  p: int

proc `=destroy`(o: Obj3) {.raises: [].} =
  try:
    mayRaise(999)
  except ValueError:
    discard

proc f3(): seq[Obj3] =
  result = @[Obj3(p: 1)]
  raise newException(IOError, "boom")

proc g3(): seq[Obj3] =
  result = @[Obj3(p: 1)]
  result = f3()

try:
  echo "returned normally: ", g3().len, " (LOST)"
except IOError:
  echo "caught IOError (OK)"
