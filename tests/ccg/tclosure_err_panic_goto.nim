discard """
  matrix: "; --panics:on"
"""
# issue #25851: --panics:on must not drop the nimErr_ check after a closure
# call whose result is consumed directly (e.g. `result.add elem(src)`).
# Regression from #25295.

type
  Overrun = object of CatchableError
  Source = object
    data: seq[bool]
    cursor: int
  ElemFn = proc(src: var Source): bool {.closure.}

proc drawBool(src: var Source): bool =
  if src.cursor >= src.data.len: raise newException(Overrun, "exhausted")
  result = src.data[src.cursor]; inc src.cursor

proc listRun(elem: ElemFn, src: var Source): seq[bool] =
  result = @[]
  while true:
    if not src.drawBool(): break
    result.add elem(src)        # closure call – the result flows straight
                                # into `add`, which previously caused the
                                # compiler to skip the nimErr_ check.

let elem: ElemFn = proc(src: var Source): bool = src.drawBool()

# Both --panics:on and --panics:off must propagate the Overrun.
var caught = false
try:
  var src = Source(data: @[true])
  discard listRun(elem, src)
except Overrun:
  caught = true
doAssert caught, "Overrun exception was swallowed"
