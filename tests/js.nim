discard """
  cmd: "nim js --hints:on $options $file"
"""

# This file tests the JavaScript generator

import
  dom, strutils

# We need to declare the used elements here. This is annoying but
# prevents any kind of typo:
var
  inputElement {.importc: "document.form1.input1", nodecl.}: ref TElement

proc OnButtonClick() {.exportc.} =
  let v = $inputElement.value
  if v.allCharsInSet(whiteSpace):
    echo "only whitespace, hu?"
  else:
    var x = parseInt(v)
    echo x*x

proc OnLoad() {.exportc.} =
  echo "Welcome! Please take your time to fill in this formular!"
