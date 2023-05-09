discard """
  action: "compile"
  cmd: "nim c -d:release -d:futureLogging $file"
"""

import std/asyncdispatch
