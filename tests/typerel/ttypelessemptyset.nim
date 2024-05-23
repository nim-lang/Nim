discard """
  errormsg: "statement returns no value that can be discarded"
"""
var q = false
discard (if q: {} else: {})

