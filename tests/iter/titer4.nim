discard """
  errormsg: "iterator within for loop context expected"
  file: "titer4.nim"
  line: 7
"""
# implicit items/pairs, but not if we have 3 for loop vars:
for x, y, z in {'a'..'z'}: #ERROR_MSG iterator within for loop context expected
  nil
