discard """
  cmd: "nim e $file"
"""

import mscriptcompiletime

macro foo =
  doAssert bar == 2
foo()
