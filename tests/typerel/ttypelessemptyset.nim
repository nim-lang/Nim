discard """
  file: "ttypelessemptyset.nim"
  errormsg: "internal error: invalid kind for last(tyEmpty)"
"""
var q = false
discard (if q: {} else: {})
