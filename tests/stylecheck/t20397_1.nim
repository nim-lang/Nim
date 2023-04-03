discard """
  matrix: "--styleCheck:off --hint:Name:on"
"""

{.hintAsError[Name]:on.}
var a_b = 1
discard a_b
{.hintAsError[Name]:off.}
