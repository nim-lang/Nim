discard """
  action: "compile"
  cmd: "nim check --warning[UnusedImport]:off $file"
"""

import std/times
