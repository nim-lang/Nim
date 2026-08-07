discard """
  output: '''
I
AM
GROOT
'''
"""

import streams

var s = newStringStream("I\nAM\nGROOT")
doAssert s.peekStr(1) == "I"
doAssert s.peekChar() == 'I'
for line in s.lines:
  echo line
s.close

var s2 = newStringStream("abc")
doAssert s2.readAll == "abc"
s2.write("def")
doAssert s2.data == "abcdef"
s2.close

# bug #26088
var s3 = newStringStream("0123456789ABCDEF")
s3.setPosition(0)
s3.write("XX")
doAssert s3.data == "XX23456789ABCDEF"
doAssert not s3.atEnd
s3.close
