discard """
  errormsg: "invalid type: 'openArray[int]' for result"
  line: 6
"""

proc foo(a: openArray[int]):auto = a
echo foo(toOpenArray([1, 2], 0, 2))
