
import asyncdispatch

proc defaultOnProgressChanged() = discard

proc ask(x: proc()) = x()

proc retrFile*(onProgressChanged: proc() {.nimcall.}): Future[void] =
  var retFuture = newFuture[void]("retrFile")
  iterator retrFileIter(): FutureBase {.closure.} =
    ask(onProgressChanged)
    complete(retFuture)

  var nameIterVar = retrFileIter
  return retFuture

discard retrFile(defaultOnProgressChanged)
