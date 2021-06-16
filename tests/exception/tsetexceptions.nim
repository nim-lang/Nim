discard """
  targets: "c cpp js"
"""

let ex = newException(CatchableError, "test")
setCurrentException(ex)
doAssert getCurrentException().msg == ex.msg
doAssert getCurrentExceptionMsg() == ex.msg
setCurrentException(nil)

try:
  raise newException(CatchableError, "test2")
except:
  setCurrentException(nil)
doAssert getCurrentException() == nil
