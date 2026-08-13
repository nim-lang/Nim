discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''ok'''
  disabled: "windows"
"""

# Dispatchers used to leak their epoll/kqueue fd: there was no way to close
# a PDispatcher, and threads/finalization never released it (bugs.txt #2).

import std/[asyncdispatch, os]

proc openFds(): int =
  when defined(macosx) or defined(bsd):
    for _ in walkDir("/dev/fd"): inc result
  else:
    for _ in walkDir("/proc/self/fd"): inc result

proc pump() =
  waitFor sleepAsync(1)

# Baseline: force one-time lazy initializations (dispatcher, selectors, etc.)
pump()
closeGlobalDispatcher()
let base = openFds()

block explicitClose:
  for i in 0..<10:
    let disp = newDispatcher()
    setGlobalDispatcher(disp)
    pump()
    closeGlobalDispatcher()
  doAssert openFds() == base, "explicit close leaks fds"

block doubleCloseIsNoop:
  let disp = newDispatcher()
  close(disp)
  close(disp)
  doAssert openFds() == base

block reuseAfterClose:
  # after closeGlobalDispatcher, async operations transparently get a fresh
  # dispatcher
  pump()
  closeGlobalDispatcher()
  doAssert openFds() == base

when defined(gcOrc) or defined(gcArc):
  block finalizerClosesDispatcher:
    proc makeAndDrop() =
      let disp = newDispatcher()
      setGlobalDispatcher(disp)
      pump()
      setGlobalDispatcher(nil)  # drop without explicit close
    for i in 0..<10:
      makeAndDrop()
    GC_fullCollect()
    doAssert openFds() == base, "finalizer did not close dispatcher"

when compileOption("threads"):
  block threadExitClosesDispatcher:
    proc worker() {.thread.} =
      waitFor sleepAsync(1)
    var threads: array[8, Thread[void]]
    for t in mitems(threads): createThread(t, worker)
    joinThreads(threads)
    doAssert openFds() == base, "thread exit leaks dispatcher fds"

echo "ok"
