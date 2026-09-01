discard """
  action: run
  targets: "c cpp"
"""

import mseq_importc_alias

type CIntAlias = cint

var fds: seq[CIntAlias]
doAssert cintLen(@[1.cint, 2.cint]) == 2
doAssert cintLen(fds) == 0
resizeCints(fds, 3)
fds[1] = CIntAlias(7)
doAssert cintLen(fds) == 3
