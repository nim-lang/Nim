discard """
  target: cpp
  action: run
  exitcode: 0
"""

import os

if paramCount() == 0:
  # main process
  doAssert execShellCmd(getAppFilename().quoteShell & " test") == 1
else:
  quit 1
