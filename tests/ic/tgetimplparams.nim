discard """
  output: '''x: float; y: float; z: var int; '''
"""

# `getImpl` of a routine loaded from another module's NIF: the formal params are
# rebuilt from the proc type and must be typed symbols, as under `nim c`
# (shady's `toShader` calls `getTypeInst` on them).

import std/macros, mgetimplparams

macro inspect(call: typed): untyped =
  let impl = call[0].getImpl
  var s = ""
  for paramDef in impl[3][1 .. ^1]:
    for param in paramDef[0 ..< ^2]:
      s.add $param & ": " & param.getTypeInst.repr & "; "
  result = newLit(s)

var z = 0
echo inspect(twice(1.0, 2.0, z))
