discard """
  matrix: "--mm:orc; --mm:arc; --mm:refc; --mm:orc --exceptions:setjmp; --mm:refc --exceptions:goto; --backend:cpp --exceptions:goto; --backend:cpp"
  output: '''
7
7
7
7
7
abc
7
3
'''
"""

# bug #26333: a variable assigned from a call that raised must keep its old value

proc g(v: int): int =
  if v == 42: raise newException(ValueError, "x")
  v

proc gs(v: int): string =
  if v == 42: raise newException(ValueError, "x")
  $v

type
  Obj = object
    x: int

proc f() =
  var y = 7
  try:
    y = g(42)
  finally:
    echo y

proc fDefer() =
  var y = 7
  defer: echo y
  y = g(42)

proc fExcept() =
  var y = 7
  try:
    y = g(42)
  except ValueError:
    echo y

proc fAfter() =
  var y = 7
  try:
    y = g(42)
  except ValueError:
    discard
  echo y

proc fField() =
  var o = Obj(x: 7)
  try:
    o.x = g(42)
  finally:
    echo o.x

proc fString() =
  var s = "abc"
  try:
    s = gs(42)
  finally:
    echo s

proc fNested() =
  var y = 7
  try:
    try:
      y = g(42)
    finally:
      discard
  except ValueError:
    echo y

proc fAfterTry() =
  # stores after a completed try/except are not observable:
  var y = 7
  try:
    discard g(1)
  except ValueError:
    discard
  y = g(3)
  try:
    y = g(42)
  finally:
    echo y

try: f()
except ValueError: discard
try: fDefer()
except ValueError: discard
fExcept()
fAfter()
try: fField()
except ValueError: discard
try: fString()
except ValueError: discard
fNested()
try: fAfterTry()
except ValueError: discard
