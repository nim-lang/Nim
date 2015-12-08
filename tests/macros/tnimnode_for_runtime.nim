discard """
  file: "tnimnode_for_runtime.nim"
  output: "bla"
"""

import macros
proc makeMacro: NimNode =
  result = nil

var p = makeMacro()

echo "bla"

