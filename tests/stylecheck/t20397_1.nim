discard """
  matrix: "--styleCheck:off"
"""

{.hintAsError[Name]:on.}
var a_b = 1
discard a_b
{.hintAsError[Name]:off.}