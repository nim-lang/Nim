discard """
  targets: "cpp"
  action: run
  exitcode: 0
"""

import os

# consider moving this inside tosproc (taking care that it's for cpp mode)

if paramCount() == 0:
  # main process
  doAssert execShellCmd(getAppFilename().quoteShell & " test") == 1
else:
  quit 1
