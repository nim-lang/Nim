discard """
  disabled: true
"""

type
  PFutureBase = ref object
    callback: proc () {.closure.}

proc newConnection =
  iterator newConnectionIter(): PFutureBase {.closure.} =
    discard
  var newConnectionIterVar = newConnectionIter
  var first = newConnectionIterVar()

  proc cb {.closure.} =
    discard

  first.callback = cb

newConnection()
