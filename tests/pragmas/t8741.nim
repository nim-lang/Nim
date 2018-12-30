discard """
  errormsg: "cannot attach a custom pragma to 'a'"
  line: 9
"""

for a {.gensym, inject.} in @[1,2,3]:
  discard

for a {.foobar.} in @[1,2,3]:
  discard
