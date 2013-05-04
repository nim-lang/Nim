discard """
  output: "bla"
  disabled: true
"""

import macros
proc makeMacro: PNimrodNode =
  result = nil

var p = makeMacro()

echo "bla"

