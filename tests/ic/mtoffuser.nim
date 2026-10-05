# Helper for ttypeoffer.nim ("db_immutable" analog): imports the codec (so
# `toSszType(Gwei)` is visible -> perChunk=4) and re-instantiates HA[64,Gwei].
# With the `(toffer …)` fix it reuses mtoffstate's instance instead.
import mtoffssz, mtoffgwei, mtoffcodec, mtoffstate
type StateB* = object
  field*: HA[64, Gwei]

proc check*() =
  static: doAssert sizeof(StateA) == sizeof(StateB)
  echo "ok"
