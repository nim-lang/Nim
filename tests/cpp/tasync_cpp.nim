discard """
  file: "tasync_cpp.nim"
  cmd: "nim cpp $file"
  output: "hello"
"""

# bug #3299

import jester
import asyncdispatch, asyncnet

echo "hello"
