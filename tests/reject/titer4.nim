discard """
  file: "titer4.nim"
  line: 7
  errormsg: "iterator within for loop context expected"
"""

for x in {'a'..'z'}: #ERROR_MSG iterator within for loop context expected
  nil


