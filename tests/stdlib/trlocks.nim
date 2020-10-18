discard """
  action: "compile"
  # Disallow joining to ensure it can compile in isolation.
  # See #15584
  joinable: false
  cmd: "nim $target --threads:on $options $file"
"""

# bugfix #15584

import rlocks

var r: RLock
r.initRLock()
