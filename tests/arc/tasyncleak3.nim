discard """
  cmd: "nim c --gc:orc -d:useMalloc $file"
  output: "true"
  valgrind: "true"
"""

import strutils

type
  FutureBase* = ref object of RootObj  ## Untyped future.
    finished: bool
    stackTrace: seq[StackTraceEntry] ## For debugging purposes only.

proc newFuture*(): FutureBase =
  new(result)
  result.finished = false
  result.stackTrace = getStackTraceEntries()

type
  PDispatcher {.acyclic.} = ref object

var gDisp: PDispatcher
new gDisp

proc testCompletion(): FutureBase =
  var retFuture = newFuture()

  iterator testCompletionIter(): FutureBase {.closure.} =
    retFuture.finished = true
    when not defined(nobug):
      let disp = gDisp # even worse memory consumption this way...

  var nameIterVar = testCompletionIter
  proc testCompletionNimAsyncContinue() {.closure.} =
    if not nameIterVar.finished:
      discard nameIterVar()
  testCompletionNimAsyncContinue()
  return retFuture

proc main =
  for i in 0..10_000:
    discard testCompletion()

main()

GC_fullCollect()
echo getOccupiedMem() < 1024
