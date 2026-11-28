discard """
  output: "minstfieldinfobox.nim(2, 2)"
"""

# The fields of a generic instance loaded from another module's NIF must keep
# their line info, as under `nim c` (stew's `recordFields` matches fields to
# their definitions by it).

import std/[macros, os], minstfieldinfobox, minstfieldinfoinst

macro fieldLineInfo(T: typedesc): untyped =
  let info = T.getTypeInst[1].getTypeImpl[2][0].lineInfoObj
  newLit(info.filename.extractFilename & "(" & $info.line & ", " & $info.column & ")")

echo fieldLineInfo(typeof(box()))
