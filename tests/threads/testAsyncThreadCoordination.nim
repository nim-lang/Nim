discard """
output:'''
Thread 1: iteration 0
Thread 2: iteration 0
Thread 1: iteration 1
Thread 2: iteration 1
Thread 1: iteration 2
Thread 2: iteration 2
Thread 1: iteration 3
Thread 2: iteration 3
Thread 1: iteration 4
Thread 2: iteration 4
Thread 1: iteration 5
Thread 2: iteration 5
Thread 1: iteration 6
Thread 2: iteration 6
Thread 1: iteration 7
Thread 2: iteration 7
Thread 1: iteration 8
Thread 2: iteration 8
Thread 1: iteration 9
Thread 2: iteration 9
Thread 1: iteration 10
Thread 2: iteration 10
Thread 1: iteration 11
Thread 2: iteration 11
Thread 1: iteration 12
Thread 2: iteration 12
Thread 1: iteration 13
Thread 2: iteration 13
Thread 1: iteration 14
Thread 2: iteration 14
Thread 1: iteration 15
Thread 2: iteration 15
Thread 1: iteration 16
Thread 2: iteration 16
Thread 1: iteration 17
Thread 2: iteration 17
Thread 1: iteration 18
Thread 2: iteration 18
Thread 1: iteration 19
Thread 2: iteration 19
Thread 1: iteration 20
Thread 2: iteration 20
Thread 1: iteration 21
Thread 2: iteration 21
Thread 1: iteration 22
Thread 2: iteration 22
Thread 1: iteration 23
Thread 2: iteration 23
Thread 1: iteration 24
Thread 2: iteration 24
Thread 1: iteration 25
Thread 2: iteration 25
Thread 1: iteration 26
Thread 2: iteration 26
Thread 1: iteration 27
Thread 2: iteration 27
Thread 1: iteration 28
Thread 2: iteration 28
Thread 1: iteration 29
Thread 2: iteration 29
Thread 1: iteration 30
Thread 2: iteration 30
Thread 1: iteration 31
Thread 2: iteration 31
Thread 1: iteration 32
Thread 2: iteration 32
Thread 1: iteration 33
Thread 2: iteration 33
Thread 1: iteration 34
Thread 2: iteration 34
Thread 1: iteration 35
Thread 2: iteration 35
Thread 1: iteration 36
Thread 2: iteration 36
Thread 1: iteration 37
Thread 2: iteration 37
Thread 1: iteration 38
Thread 2: iteration 38
Thread 1: iteration 39
Thread 2: iteration 39
Thread 1: iteration 40
Thread 2: iteration 40
Thread 1: iteration 41
Thread 2: iteration 41
Thread 1: iteration 42
Thread 2: iteration 42
Thread 1: iteration 43
Thread 2: iteration 43
Thread 1: iteration 44
Thread 2: iteration 44
Thread 1: iteration 45
Thread 2: iteration 45
Thread 1: iteration 46
Thread 2: iteration 46
Thread 1: iteration 47
Thread 2: iteration 47
Thread 1: iteration 48
Thread 2: iteration 48
Thread 1: iteration 49
Thread 2: iteration 49
Thread 1: iteration 50
Thread 1: done
Thread 2: iteration 50
Thread 2: done
'''
"""

import os, asyncdispatch

type
  ThreadArg = object
    event1: AsyncEvent
    event2: AsyncEvent

when not(compileOption("threads")):
  {.fatal: "Please, compile this program with the --threads:on option!".}

proc wait(event: AsyncEvent): Future[void] =
  var retFuture = newFuture[void]("AsyncEvent.wait")
  proc continuation(fd: AsyncFD): bool {.gcsafe.} =
    if not retFuture.finished:
      retFuture.complete()
    result = true
  addEvent(event, continuation)
  return retFuture

proc asyncProc1(args: ThreadArg) {.async.} =
  for i in 0 .. 50:
    # why 50 iterations? It's arbitrary. We can't run forever, but we want to run long enough
    # to sanity check against a race condition or deadlock.
    let waiting = args.event1.wait()
    args.event2.trigger()
    await waiting
    # Why echoes and not just a count? Because this test is about coordination of threads.
    # We need to make sure the threads get properly synchronized on each iteration.
    echo "Thread 1: iteration ", i
  args.event2.trigger()
  echo "Thread 1: done"

proc asyncProc2(args: ThreadArg) {.async.} =
  for i in 0 .. 50:
    let waiting = args.event2.wait()
    args.event1.trigger()
    await waiting
    echo "Thread 2: iteration ", i
  args.event1.trigger()
  echo "Thread 2: done"

proc threadProc1(args: ThreadArg) {.thread.} =
  ## We create new dispatcher explicitly to avoid bugs.
  let loop = getGlobalDispatcher()
  waitFor asyncProc1(args)

proc threadProc2(args: ThreadArg) {.thread.} =
  ## We create new dispatcher explicitly avoid bugs.
  let loop = getGlobalDispatcher()
  waitFor asyncProc2(args)

proc main() =
  var
    args: ThreadArg
    thread1: Thread[ThreadArg]
    thread2: Thread[ThreadArg]

  args.event1 = newAsyncEvent()
  args.event2 = newAsyncEvent()
  thread1.createThread(threadProc1, args)
  sleep(1)
  thread2.createThread(threadProc2, args)
  joinThreads(thread1, thread2)

when isMainModule:
  main()
