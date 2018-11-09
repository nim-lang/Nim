discard """
  line: 9
  errormsg: "illegal discard"
"""

proc pop[T](arg: T): T =
  echo arg

discard tillegaldiscard.pop
