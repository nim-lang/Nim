discard """
  errormsg: "value expected, but got a type"
  line: 7
"""

proc crashAndBurn() =
  var stuff = seq[tuple[title, body: string]]


crashAndBurn()
