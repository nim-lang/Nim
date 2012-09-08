discard """
  output: "21"
"""

import macros

type
  TMat = object
    dummy: int

proc `*`(a, b: TMat): TMat = nil
proc `+`(a, b: TMat): TMat = nil
proc `-`(a, b: TMat): TMat = nil
proc `$`(a: TMat): string = result = $a.dummy

macro optOps{ (`+`|`-`|`*`) *| a }(a: TMat): expr =
  result = callsite()

#macro optPlus{ `+` * a }(a: varargs[TMat]): expr =
#  result = newIntLitNode(21)

var x, y, z: TMat

echo x + y * z - x 

#echo x + y + z
