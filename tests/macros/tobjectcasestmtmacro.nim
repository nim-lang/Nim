discard """
  output: "macro called"
"""

{.experimental: "caseStmtMacros".}

import macros

type
  Base = ref object of RootObj

macro `case`(obj: Base): untyped =
  quote do:
    echo "macro called"

case Base()
of 1:
  discard
