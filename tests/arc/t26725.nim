discard """
  matrix: "--mm:arc; --mm:orc"
"""

# bug #26725: a write on a path that does not reach the next assignment
# as an initialization still leaves a value that must be destroyed

type
  Obj = object
  O = ref Obj

var destroyed = 0
proc `=destroy`(x: Obj) = inc destroyed

proc mk(): O = O()

proc f(cond: bool) =
  var s: O
  if cond:
    s = O()
  s = nil

proc fElse(cond: bool) =
  var s: O
  if cond:
    discard
  else:
    s = O()
  s = nil

proc fCase(k: int) =
  var s: O
  case k
  of 0: s = O()
  of 1: discard
  else: discard
  s = nil

proc fElifCond(a: bool) =
  var s: O
  if a:
    discard
  elif (s = O(); false):
    discard
  else:
    s = nil # `s` was written by the `elif` condition

proc fNested(a, b: bool) =
  var s: O
  if a:
    if b:
      s = O()
  s = mk()

proc fLoop() =
  var i = 0
  while i < 3:
    var s: O
    if i mod 2 == 0:
      s = O()
    s = nil
    inc i

proc fTry(cond: bool) =
  var s: O
  try:
    s = O()
    if cond: raise newException(ValueError, "x")
  except ValueError:
    discard
  s = nil

proc fBlock(cond: bool) =
  var s: O
  block b:
    s = O()
    if cond: break b
  s = nil

proc fBoth(cond: bool) =
  # both branches are first writes, only one of them runs
  var s: O
  if cond:
    s = O()
  else:
    s = mk()
  s = nil

destroyed = 0
f(true)
doAssert destroyed == 1
f(false)
doAssert destroyed == 1

destroyed = 0
fElse(false)
doAssert destroyed == 1

destroyed = 0
fCase(0)
doAssert destroyed == 1

destroyed = 0
fElifCond(false)
doAssert destroyed == 1

destroyed = 0
fNested(true, true)
doAssert destroyed == 2

destroyed = 0
fLoop()
doAssert destroyed == 2

destroyed = 0
fTry(true)
doAssert destroyed == 1
fTry(false)
doAssert destroyed == 2

destroyed = 0
fBlock(true)
doAssert destroyed == 1

destroyed = 0
fBoth(true)
doAssert destroyed == 1
fBoth(false)
doAssert destroyed == 2
