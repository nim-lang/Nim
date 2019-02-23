discard """
  errormsg: "illegal discard"
  line: 9
"""

proc pop[T](arg: T): T =
  echo arg

discard tillegaldiscard.pop
