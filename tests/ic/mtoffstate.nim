# Helper for ttypeoffer.nim ("datatypes" analog): instantiates HA[64,Gwei] WITHOUT
# the codec in scope -> perChunk=1. This is the instance that must be shared.
import mtoffssz, mtoffgwei
type StateA* = object
  field*: HA[64, Gwei]
