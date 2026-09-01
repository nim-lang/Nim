# Helper for tinitorder (not a test itself; no `discard`).
#
# An imported module whose INIT sets module-level state at runtime. Under the
# per-module backend its init must run BEFORE any importer's init (the imported
# module is a dependency → post-order). With the buggy importer-first order this
# module's `setupB` runs too late and importers observe `gBState == 0`.

var gBState: int

proc getBState*(): int = gBState

proc setupB() =
  gBState = 42

setupB()
