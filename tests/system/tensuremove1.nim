discard """
  errormsg: "cannot move 's', which introduces an implicit copy"
  matrix: "--cursorinference:on; --cursorinference:off"
"""

type
  String = object
    id: string

proc hello =
  var s = String(id: "1")
  var m = ensureMove s
  discard m
  discard s

hello()