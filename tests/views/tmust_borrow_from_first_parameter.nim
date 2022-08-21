discard """
  errormsg: "'result' must borrow from the first parameter"
  line: 9
"""

{.experimental: "views".}

proc p(a, b: openArray[char]): openArray[char] =
  result = b
