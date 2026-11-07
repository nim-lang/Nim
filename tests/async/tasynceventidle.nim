discard """
  joinable: false
"""

import std/asyncdispatch
import masynceventlifetime

block:
  var destroyed = 0
  let ev = newAsyncEvent()
  watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
    doAssert false, "unregistered callback")
  ev.unregister()
  ev.close()
  retireAll()
  checkDestroyed(destroyed, 1)
