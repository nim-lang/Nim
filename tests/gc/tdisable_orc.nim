discard """
  joinable: false
"""

import std/asyncdispatch

# bug #22256
GC_disableMarkAndSweep()
waitFor sleepAsync(1000)
