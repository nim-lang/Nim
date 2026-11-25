discard """
  matrix: "--mm:orc"
  output: '''
@[1, 2, 3]
@[1, 2, 3]
@[4, 5]
@[1, 2, 3]
@[1, 2, 3]
'''
"""

# bug #26567: the `lent` value of a value producing construct must not
# outlive what it borrows from

type
  Obj = object
    s: seq[int]
  A = ref Obj

proc `=destroy`(o: Obj) =
  # make a dangling read visible:
  if o.s.len > 0: (addr o.s[0])[] = -1
  `=destroy`(o.s)

proc mk(x: varargs[int]): seq[int] =
  # not a constant seq: the destructor writes to it
  for it in x: result.add it

proc view(o: A): lent seq[int] = o.s

proc p(): seq[int] =
  defer: discard
  view(A(s: mk(1, 2, 3)))

echo p()

proc q(b: bool): seq[int] =
  defer: discard
  if b: view(A(s: mk(1, 2, 3)))
  else: raise newException(ValueError, "x")

echo q(true)

proc r(i: int): seq[int] =
  defer: discard
  case i
  of 0: view(A(s: mk(4, 5)))
  else: view(A(s: mk(6)))

echo r(0)

var a = A(s: mk(1, 2, 3))

proc view(): lent seq[int] = a.s

iterator it(): int {.closure.} =
  let r = (block:
    defer:
      a = nil
      yield 1
    view())
  echo r

for _ in it(): discard

a = A(s: mk(1, 2, 3))

iterator it2(): int {.closure.} =
  let r = (if a != nil:
    defer:
      a = nil
      yield 1
    view()
  else:
    view())
  echo r

for _ in it2(): discard
