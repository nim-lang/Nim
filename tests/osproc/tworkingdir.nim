discard """
  file: "tworkingdir.nim"
  output: ""
"""

import osproc, os
when defined(windows):
  # Windows don't have this issue, so we won't test it.
  discard
else:
  let dir1 = getCurrentDir()
  var process = startProcess("/usr/bin/env", "/usr/bin", ["true"])
  let dir2 = getCurrentDir()
  discard process.waitForExit()
  process.close()
  doAssert(dir1 == dir2, $dir1 & " != " & $dir2)
