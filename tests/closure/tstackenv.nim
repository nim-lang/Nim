discard """
  target: "c"
"""

type Thing {.byref.} = object
  x: int

proc paramWasntCopied(t: Thing; tAddr: ptr Thing) =
  # stack closures don't copy captured params but rather
  # store ptrs to them
  var y = 0
  proc inner =
    y += t.x
  
  inner()
  doAssert y == t.x
  let myAddr = unsafeAddr(t)
  # since no copy occured we should have the same address
  doAssert myAddr == tAddr

proc paramWasCopied(t: Thing; tAddr: ptr Thing): proc =
  var y = 0
  proc inner =
    y += t.x
  
  inner()
  doAssert y == t.x
  let myAddr = unsafeAddr(t)
  doAssert myAddr != tAddr
  return inner

proc captureVarParam(t: var Thing) = 
  # stack closures can capture var params
  proc inner =
    t.x += 10
  
  inner()

proc foo =
  var t = Thing(x: 10)
  let tAddr = addr(t)
  paramWasntCopied(t, tAddr)
  discard paramWasCopied(t, tAddr)
  captureVarParam(t)
  doAssert t.x == 20

foo()