import std/asyncdispatch

when defined(gcArc) or defined(gcOrc):
  const
    mmName = when defined(gcArc): "arc" else: "orc"
    maxSpins = 128

  type
    TrackerObj = object
      id: int

  var
    destroyedCount = 0
    nextId = 0

  proc `=destroy`(x: var TrackerObj) =
    inc destroyedCount

  proc newTracker(): ref TrackerObj =
    inc nextId
    new result
    result.id = nextId

  proc spinUntil(cond: proc (): bool {.closure.}; budget: int): int =
    result = 0
    while not cond() and result < budget:
      try:
        poll(0)
      except ValueError as e:
        if e.msg != "No handles or timers registered in dispatcher.":
          raise
      inc result

  proc ensureAsyncCheckReleasesEnv() =
    let expectedDestroyed = destroyedCount + 1
    var finished = false
    block:
      var tracker = newTracker()
      let expectedId = tracker.id

      proc worker(): Future[void] {.async.} =
        doAssert expectedId > 0
        doAssert not tracker.isNil,
          mmName & " tracker should stay alive before await"
        await sleepAsync(0)
        doAssert not tracker.isNil,
          mmName & " tracker should stay alive until async step finishes"
        finished = true

      var fut = worker()
      asyncCheck fut

      let spins = spinUntil(proc (): bool = finished, maxSpins)
      doAssert finished,
        mmName & " asyncCheck future should finish within polling budget"
      doAssert spins < maxSpins,
        mmName & " asyncCheck future waited too long to finish"

      discard spinUntil(proc (): bool = destroyedCount >= expectedDestroyed, maxSpins)

      fut = nil
      tracker = nil

    discard spinUntil(proc (): bool = destroyedCount >= expectedDestroyed, maxSpins)

    doAssert destroyedCount == expectedDestroyed,
      mmName & " asyncCheck should release captured refs in same turn"

  proc ensureFutureCallbackBreaksCycle() =
    let expectedDestroyed = destroyedCount + 1
    var callbackRan = false
    block:
      var tracker = newTracker()
      let expectedId = tracker.id
      var fut = newFuture[int]("async closure cycle")
      doAssert not fut.isNil,
        mmName & " future allocation failed unexpectedly"
      let capturedFuture = fut

      fut.addCallback(proc () =
        doAssert not capturedFuture.isNil
        doAssert capturedFuture.read() == expectedId
        doAssert tracker.id == expectedId
        callbackRan = true
      )

      fut.complete(expectedId)

      let spins = spinUntil(proc (): bool = callbackRan, maxSpins)
      doAssert callbackRan,
        mmName & " future callback should run within polling budget"
      doAssert spins < maxSpins,
        mmName & " future callback took too long to run"

      discard spinUntil(proc (): bool = destroyedCount >= expectedDestroyed, maxSpins)

      fut = nil
      tracker = nil

    discard spinUntil(proc (): bool = destroyedCount >= expectedDestroyed, maxSpins)

    doAssert destroyedCount == expectedDestroyed,
      mmName & " future callback cycle should be broken deterministically"

  const runs = 3

  destroyedCount = 0
  nextId = 0
  for _ in 0..<runs:
    ensureAsyncCheckReleasesEnv()

  doAssert destroyedCount == runs,
    mmName & " asyncCheck runs should not leak captured refs"

  for _ in 0..<runs:
    ensureFutureCallbackBreaksCycle()

  doAssert destroyedCount == runs * 2,
    mmName & " future callback cycles should not leak captured refs"
else:
  {.fatal: "This test must run with --mm:arc or --mm:orc".}
