discard """
  cmd: r"nim c --hints:on $options --threads:on $file"
"""

import algorithm

# bug #1657
var modules = @["hi", "ho", "ha", "huu"]
sort(modules, system.cmp)
