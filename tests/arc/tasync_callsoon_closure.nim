import std/asyncdispatch

when defined(gcArc) or defined(gcOrc):
  const mmName = when defined(gcArc): "arc" else: "orc"

  type
    TrackerObj = object
      id: int

  var
    destroyedCount = 0
    nextId = 0

  const
    runs = 3
    maxPollSpins = 256

  proc `=destroy`(x: var TrackerObj) =
    inc destroyedCount

  proc newTracker(): ref TrackerObj =
    inc nextId
    new result
    result.id = nextId

  proc ensureCallbackReleasesEnv(iteration: int) =
    var finished = false
    block:
      var tracker = newTracker()
      callSoon(proc () =
        doAssert tracker.id == iteration + 1
        finished = true
      )
      while not finished:
        poll(0)
      tracker = nil
    var releaseSpins = 0
    while destroyedCount < iteration + 1 and releaseSpins < maxPollSpins:
      try:
        poll(0)
      except ValueError:
        discard
      inc releaseSpins
    doAssert destroyedCount == iteration + 1,
      mmName & " callSoon should deterministically release the closure environment"

  destroyedCount = 0
  nextId = 0
  for i in 0..<runs:
    ensureCallbackReleasesEnv(i)

  doAssert destroyedCount == runs,
    mmName & " callSoon should not leak captured references"
else:
  {.fatal: "This test must run with --mm:arc or --mm:orc".}
