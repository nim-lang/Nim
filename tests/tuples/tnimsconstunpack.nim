discard """
  action: compile
  cmd: "nim e $file"
"""

import mnimsconstunpack

doAssert b == "b"
