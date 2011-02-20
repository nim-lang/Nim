discard """
  file: "ttypelessemptyset.nim"
  line: 5
  errormsg: "Error: internal error: invalid kind for last(tyEmpty)"
"""
var q = false
discard (if q: {} else: {})




