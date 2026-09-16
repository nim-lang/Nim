discard """
  cmd: "nim ic --run $options $file argument --program-option"
  action: compile
  nimout: "IC argument: argument"
"""

import std/os

doAssert paramCount() == 2
doAssert paramStr(2) == "--program-option"
echo "IC argument: ", paramStr(1)
