# This file tests the ECMAScript generator

import
  dom, strutils

# We need to declare the used elements here. This is annoying but
# prevents any kind of typo:
var
  inputElement {.importc: "document.form1.input", nodecl.}: ref TElement

proc OnButtonClick() {.exportc.} =
  var x: int = parseInt($inputElement.value)
  echo($(x * x))

proc OnLoad() {.exportc.} = 
  echo("Welcome! Please take your time to fill in this formular!")
