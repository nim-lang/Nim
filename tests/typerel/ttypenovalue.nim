discard """
  errormsg: "invalid type: 'typedesc[seq[tuple[title: string, body: string]]]' for var"
  line: 7
"""

proc crashAndBurn() =
  var stuff = seq[tuple[title, body: string]]


crashAndBurn()
