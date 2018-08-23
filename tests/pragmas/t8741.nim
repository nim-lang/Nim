discard """
  line: 9
  errormsg: "attempting to call undeclared routine: 'foobar'"
"""

for a {.gensym, inject.} in @[1,2,3]:
  discard

for a {.foobar.} in @[1,2,3]:
  discard
