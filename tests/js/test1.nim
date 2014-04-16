discard """
  output: "1261129"
"""

# This file tests the JavaScript generator

import
  dom, strutils

var
  inputElement = "1123"

proc OnButtonClick(inputElement: string) {.exportc.} =
  let v = $inputElement
  if v.allCharsInSet(whiteSpace):
    echo "only whitespace, hu?"
  else:
    var x = parseInt(v)
    echo x*x

onButtonClick(inputElement)

