discard """
  line: 9
  errormsg: "cannot attach a custom pragma to 'a'"
"""

for a {.gensym, inject.} in @[1,2,3]:
  discard

for a {.foobar.} in @[1,2,3]:
  discard
