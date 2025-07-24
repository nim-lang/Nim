discard """
  matrix: "--mm:refc; --mm:arc"
"""

# bug #19457
proc gcd(x, y: seq[int]): seq[int] =
    var
      a = x
      b = y
    while b[0] > 0:
      let c = @[a[0] mod b[0]]
      a = b
      b = c
    return a

doAssert gcd(@[1], @[2]) == @[1]



import std/sequtils

type IrrelevantType* = object

proc `=copy`*(dest: var IrrelevantType, src: IrrelevantType) =
  discard

type
  Inner* = object
    value*: string
    someField*: IrrelevantType
  
  Outer* = object
    inner*: Inner

iterator valueIt(self: Outer): Inner =
  yield self.inner

proc getValues*(self: var Outer): seq[Inner] =
  var peers = self.valueIt().toSeq
  return peers

var outer = Outer()

outer.inner = Inner(value: "hello, world")

doAssert (outer.valueIt().toSeq)[0].value == "hello, world" # Passes
doAssert outer.inner.value == "hello, world" # Passes too, original value is doing fine
doAssert outer.getValues()[0].value == "hello, world" # Fails, value is empty
