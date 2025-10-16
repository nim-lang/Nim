discard """
  cmd: '''nim r --threads:on $file'''
"""

import std/[asyncdispatch, os, strutils]

when defined(gcArc) or defined(gcOrc):
  static:
    when not compileOption("threads"):
      {.error: "This test requires --threads:on".}

  const
    mmName = when defined(gcArc): "arc" else: "orc"
    maxSpins = 128
    runs = 4

  type
    TrackerObj = object
      id: int

    CrossThreadArgs = object
      fut: Future[int]
      value: int

  var
    destroyedCount = 0
    nextId = 0

  proc `=destroy`(x: var TrackerObj) =
    inc destroyedCount

  proc newTracker(): ref TrackerObj =
    inc nextId
    new result
    result.id = nextId

  proc runCrossThreadFuture(iteration: int) =
    let expectedDestroyed = destroyedCount + 1
    var callbackRan = false

    block:
      var tracker = newTracker()
      let expectedId = tracker.id
      let fut = newFuture[int]("async cross-thread completion")
      let capturedFuture = fut

      fut.addCallback(proc () =
        doAssert not capturedFuture.isNil
        doAssert capturedFuture.finished,
          mmName & " future should be finished when callback runs"
        doAssert capturedFuture.read() == expectedId,
          mmName & " future should carry the expected value"
        doAssert tracker.id == expectedId,
          mmName & " tracker should stay alive until callback"
        callbackRan = true
      )

      proc completeInThread(args: CrossThreadArgs) =
        args.fut.complete(args.value)

      var worker: Thread[CrossThreadArgs]
      createThread(worker, completeInThread,
        CrossThreadArgs(fut: fut, value: expectedId))

      var spins = 0
      while not callbackRan and spins < maxSpins:
        try:
          poll(0)
        except ValueError as e:
          if "No handles or timers registered" in e.msg:
            sleep(1)
          else:
            raise
        inc spins

      joinThread(worker)

      doAssert callbackRan,
        mmName & " cross-thread future callback should trigger"

      tracker = nil

      if destroyedCount < expectedDestroyed:
        var releaseSpins = 0
        while destroyedCount < expectedDestroyed and releaseSpins < maxSpins:
          try:
            poll(0)
          except ValueError as e:
            if "No handles or timers registered" in e.msg:
              sleep(1)
            else:
              raise
          inc releaseSpins
        doAssert releaseSpins < maxSpins,
          mmName & " cross-thread future release took too long"

      doAssert destroyedCount == expectedDestroyed,
        mmName & " cross-thread future should release captured refs"
      doAssert spins < maxSpins,
        mmName & " cross-thread future took too long to finish"

  proc runAsyncCheckException(iteration: int) =
    let expectedDestroyed = destroyedCount + 1
    block:
      var tracker = newTracker()
      let expectedId = tracker.id

      var fut = newFuture[void]("asyncCheck failure path")
      doAssert not fut.isNil,
        mmName & " failing future allocation should succeed"
      asyncCheck fut

      let failureError = newException(ValueError,
        "asyncCheck failure " & $expectedId)

      var failureSeen = false
      try:
        fut.fail(failureError)
      except CatchableError as e:
        let isFailure = "asyncCheck failure" in e.msg
        failureSeen = failureSeen or isFailure
        if not isFailure:
          raise

      var failureSpins = 0
      while not failureSeen and failureSpins < maxSpins:
        try:
          poll(0)
        except CatchableError as e:
          let isFailure = "asyncCheck failure" in e.msg
          failureSeen = failureSeen or isFailure
          if "No handles or timers registered" in e.msg:
            sleep(1)
          elif not isFailure:
            raise
        inc failureSpins

      tracker = nil

      if destroyedCount < expectedDestroyed:
        var releaseSpins = 0
        while destroyedCount < expectedDestroyed and releaseSpins < maxSpins:
          try:
            poll(0)
          except CatchableError as e:
            let isFailure = "asyncCheck failure" in e.msg
            failureSeen = failureSeen or isFailure
            if "No handles or timers registered" in e.msg:
              sleep(1)
            elif not isFailure:
              raise
          inc releaseSpins
        doAssert releaseSpins < maxSpins,
          mmName & " asyncCheck failure release took too long"

      doAssert fut.isNil or fut.failed,
        mmName & " asyncCheck future should record the failure"
      doAssert failureSeen,
        mmName & " asyncCheck should surface the failure"

    doAssert destroyedCount == expectedDestroyed,
      mmName & " asyncCheck failure should release captured refs"

  destroyedCount = 0
  nextId = 0
  for i in 0..<runs:
    runCrossThreadFuture(i)

  doAssert destroyedCount == runs,
    mmName & " cross-thread future runs should not leak captured refs"

  for i in 0..<runs:
    runAsyncCheckException(i)

  doAssert destroyedCount == runs * 2,
    mmName & " asyncCheck exception runs should not leak captured refs"
else:
  {.fatal: "This test must run with --mm:arc or --mm:orc".}
