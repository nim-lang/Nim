discard """
  file: "idents.nim"
  line: 42
  errormsg: "Unicode dashes not working"
"""

echo "Idents test with Unicode magic chars"
var foo⋯bar = 1, bar⋯scumm = 47

echo "Idents test Compare"
var bazma = foo⋯bar == foobar

echo "Idents test done: " & $bazma
