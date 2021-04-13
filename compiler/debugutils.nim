##[
Utilities to help with debugging nim compiler.

Experimental API, subject to change.
]##

import options

var conf0: ConfigRef

proc onNewConfigRef*(conf: ConfigRef) {.inline.} =
  ## Caches `conf`, which can be retrieved with `getConfigRef`.
  ## This avoids having to forward `conf` all the way down the call chain to
  ## procs that need it during a debugging session.
  conf0 = conf

proc getConfigRef*(): ConfigRef =
  ## nil, if -d:nimDebugUtils wasn't specified
  result = conf0

proc nimDebugutilsGetConfigRef*(): ConfigRef {.exportc.} =
  conf0
