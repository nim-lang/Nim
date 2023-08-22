discard """
  output: ""
"""

import osproc, os
when defined(windows):
  # Windows don't have this issue, so we won't test it.
  discard
else:
  let dir1 = getCurrentDir()
  var process: Process
  when defined(android):
    process = startProcess("/system/bin/env", "/system/bin", ["true"])
  elif defined(haiku):
    process = startProcess("/bin/env", "/bin", ["true"])
  else:
    process = startProcess("/usr/bin/env", "/usr/bin", ["true"])
  let dir2 = getCurrentDir()
  discard process.waitForExit()
  process.close()
  doAssert(dir1 == dir2, $dir1 & " != " & $dir2)
