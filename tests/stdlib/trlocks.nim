discard """
  action: "compile"
  cmd: "nim c --threads:on $file"
"""

# bug #15584

import rlocks

var r: RLock
r.initRLock()
