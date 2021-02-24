discard """
  cmd: "nim $target --threads:on $options $file"
"""

import rlocks

var r: RLock
r.initRLock()
doAssert r.tryAcquire()
doAssert r.tryAcquire()
r.release()
r.release()
r.deinitRLock()
