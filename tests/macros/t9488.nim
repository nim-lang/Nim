# bug #9488: an inner proc of a macro passed as a proc value
import std/macros

proc take(x: proc(): bool): bool = x()

macro triggerBug(updId: bool): untyped =
  doAssert updId.boolVal
  proc filt(): bool = updId.boolVal
  doAssert take(filt)
  result = newLit(take filt)

doAssert triggerBug(true)
