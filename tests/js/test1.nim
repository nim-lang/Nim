discard """
  output: "1261129"
"""

# This file tests the JavaScript generator

import strutils

var
  inputElement = "1123"

proc onButtonClick(inputElement: string) {.exportc.} =
  let v = $inputElement
  if v.allCharsInSet(WhiteSpace):
    echo "only whitespace, hu?"
  else:
    var x = parseInt(v)
    echo x*x

onButtonClick(inputElement)

block:
  var s: string
  s.add("hi")
  doAssert(s == "hi")

block:
  var s: string
  s.insert("hi", 0)
  doAssert(s == "hi")

block:
  var s: string
  s.setLen(2)
  s[0] = 'h'
  s[1] = 'i'
  doAssert(s == "hi")

block:
  var s: seq[int]
  s.setLen(2)
  doAssert(s == @[0, 0])

block:
  var s: seq[int]
  s.insert(2, 0)
  doAssert(s == @[2])

block:
  var s: seq[int]
  s.add(2)
  doAssert(s == @[2])
