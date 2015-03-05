discard """
  output: "bla"
"""

import macros
proc makeMacro: PNimrodNode =
  result = nil

var p = makeMacro()

echo "bla"

