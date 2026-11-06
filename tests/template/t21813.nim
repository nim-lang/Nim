discard """
action: reject
errormsg: "conversion from int literal(15) to range -10..10(int)"
"""

# bug #21813

proc p*[S: Ordinal](value: S) =
  discard
p[range[-10..10]](15)
