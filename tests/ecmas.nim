# This file tests the ECMAScript generator

import
  dom, strutils

# We need to declare the used elements here. This is annoying but
# prevents any kind of typo:
var
  inputElement {.importc: "document.form1.input1", nodecl.}: ref TElement

proc OnButtonClick() {.exportc.} =
  #var x = parseInt($inputElement.value)
  #echo($(x * x))
  var input = $inputElement.value
  echo "Test"
  echo "Hi, ", input

proc OnLoad() {.exportc.} = 
  echo "Welcome! Please take your time to fill in this formular!"
