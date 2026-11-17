discard """
  errormsg: "type mismatch"
  line: 7
"""

proc g[N: static int]() = discard
iterator d: int = g[(; yield 0; 5)]()
for _ in d(): doAssert false
