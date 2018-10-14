discard """
  line: 6
  errormsg: "invalid type: 'openarray[int]' for result"
"""

proc foo(a: openArray[int]):auto = a
echo foo(toOpenArray([1, 2], 0, 2))
