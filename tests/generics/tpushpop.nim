discard """
  matrix: "--warningAsError:Deprecated"
"""

proc y() {.deprecated.} = discard
proc v(_: int | int) =
  {.push warning[Deprecated]: off.}
  y()
  {.pop.}

v(1)