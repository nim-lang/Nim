discard """
  errormsg: "Nested expressions cannot be moved: 'if true: s else: String()'"
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