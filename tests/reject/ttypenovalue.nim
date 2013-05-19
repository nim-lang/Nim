discard """
  errormsg: "value expected, but got a type"
  line: 7
  disabled: true
"""

proc crashAndBurn() =
  var stuff = seq[tuple[title, body: string]]


crashAndBurn()
