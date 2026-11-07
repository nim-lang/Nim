discard """
  errormsg: "type mismatch"
  line: 9
"""

# bug #26556: a statement list expression containing `yield` is not a
# constant even though its last expression is an int literal
proc g(_: static int) = discard
iterator d: int = g((; yield 0; 0))
for _ in d(): doAssert false
