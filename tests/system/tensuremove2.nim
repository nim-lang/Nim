discard """
  errormsg: "'if true: s else: String()' is not a mutable location; it cannot be moved"
"""

type
  String = object
    id: string

proc hello =
  var s = String(id: "1")
  var m = ensureMove(if true: s else: String())
  discard m
  discard s

hello()