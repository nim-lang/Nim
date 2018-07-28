discard """
  output: '''OK'''
"""

#bug #8468

import encodings, strutils

var utf16LEConverter = open(destEncoding = "utf-16", srcEncoding = "utf-8")
var s = "some string"
var c = utf16LEConverter.convert(s)

var z = newStringOfCap(s.len * 2)
for x in s:
  z.add x
  z.add chr(0)

doAssert z == c
echo "OK"
