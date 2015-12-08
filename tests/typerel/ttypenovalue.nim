discard """
  file: "ttypenovalue.nim"
  errormsg: "value expected, but got a type"
  line: 8
  disabled: true
"""

proc crashAndBurn() =
  var stuff = seq[tuple[title, body: string]]


crashAndBurn()
