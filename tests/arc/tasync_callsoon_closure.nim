import std/asyncdispatch

when not (defined(gcArc) or defined(gcOrc)):
  {.fatal: "This test must run with --mm:arc or --mm:orc".}

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

proc ensureCallbackReleasesEnv(iteration: int) =
  var finished = false
  block:
    let tracker = newTracker()
    callSoon(proc () =
      doAssert tracker.id == iteration + 1
      finished = true
    )
    while not finished:
      poll(0)
  doAssert destroyedCount == iteration + 1

const runs = 3

destroyedCount = 0
nextId = 0
for i in 0..<runs:
  ensureCallbackReleasesEnv(i)
