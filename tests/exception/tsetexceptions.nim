discard """
  targets: "c cpp js"
"""

let ex = newException(CatchableError, "test")
setCurrentException(ex)
doAssert getCurrentException().msg == ex.msg
doAssert getCurrentExceptionMsg() == ex.msg
