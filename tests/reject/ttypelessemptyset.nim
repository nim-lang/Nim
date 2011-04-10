discard """
  file: "ttypelessemptyset.nim"
  line: 5
  errormsg: "internal error: invalid kind for last(tyEmpty)"
"""
var q = false
discard (if q: {} else: {})




