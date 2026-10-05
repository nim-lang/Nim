# Helper for tinitorder (not a test itself; no `discard`).
#
# Imports minitorderb and, in its OWN init, reads the state minitorderb set up.
# With the wrong (importer-first) init order `gBState` is still 0 here. It also
# allocates a seq in its init so that under `--mm:refc` the GC (set up by the
# system module's init) must already be live — i.e. the system module's init has
# to be ordered first.

import minitorderb

var
  gASawB = -1
  gAItems: seq[int]

proc getASawB*(): int = gASawB
proc getACount*(): int = gAItems.len

proc recordA() =
  gASawB = getBState()
  gAItems = @[1, 2, 3]
  # Allocate (and drop) enough garbage to force a GC cycle DURING module init.
  # Under refc that runs a conservative stack scan, which needs the main
  # thread's stack bottom already set — i.e. `initStackBottomWith` must run
  # before the module inits, not after them.
  for i in 0 ..< 100_000:
    let s = @[i, i + 1, i + 2]
    doAssert s.len == 3

recordA()
