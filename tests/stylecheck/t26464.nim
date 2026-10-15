discard """
  matrix: "--styleCheck:usages --styleCheck:error"
  output: "cmd1"
"""

# bug #26464: a type node taken from `getTypeImpl` carries the line info of
# the field it belongs to; the style checker must not compare `Cmd` to `cmd`.

import std/macros

type
  Cmd = enum
    cmd1, cmd2

  Conf = object
    cmd: Cmd

macro defaultOfFieldType(T: typedesc): untyped =
  let typ = T.getTypeInst[1].getTypeImpl[2][0][1]
  result = newCall(bindSym"default", newTree(nnkTypeOfExpr, typ))

let x = defaultOfFieldType(Conf)
echo x
