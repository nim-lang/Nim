discard """
  errormsg: "cannot convert 101 to BelowFive"
  line: 8
"""

# bug #8422
type BelowFive = range[0 .. 4]
const d = BelowFive(1).succ(100)
