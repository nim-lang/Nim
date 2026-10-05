type CFloatAlias* {.importc: "float", nodecl.} = float32

proc clearImported*(s: var seq[CFloatAlias]) =
  s.setLen(0)
