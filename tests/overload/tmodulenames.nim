discard """
  file: "tmodulenames.nim"
  line: 13
  errormsg: "type mismatch: got (two.typ)"
"""
# Issue 78 - https://github.com/Araq/Nimrod/issues/78
import one, two

proc test(testing: one.typ) =
  nil

var s: two.typ
test(s)
