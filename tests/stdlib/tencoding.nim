discard """
  output: '''OK'''
"""

#bug #8468

import encodings, strutils

when defined(windows):
  var utf16to8 = open(destEncoding = "utf-16", srcEncoding = "utf-8")
  var s = "some string"
  var c = utf16to8.convert(s)

  var z = newStringOfCap(s.len * 2)
  for x in s:
    z.add x
    z.add chr(0)

  doAssert z == c

echo "OK"
