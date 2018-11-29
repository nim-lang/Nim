discard """
  errormsg: "\'method\' needs a parameter that has an object type"
  file: "tmethod.nim"
  line: 7
"""

method m(i: int): int =
  return 5
