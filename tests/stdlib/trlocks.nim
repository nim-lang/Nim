discard """
  action: "compile"
  cmd: "nim $target --threads:on $options $file"
"""

# bugfix #15584

import rlocks

var r: RLock
r.initRLock()
