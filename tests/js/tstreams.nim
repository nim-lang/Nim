discard """
  output: '''
I
AM
GROOT
'''
"""

import streams

block:
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


block:
  proc fun[T](x: T) =
    # todo: this could be done via `write` on a StringStream
    var str: string
    str.setLen 10
    for i in 0..<T.sizeof: # improve
      str[i] = cast[char](255 and (x shr (i*8)))

    var s = newStringStream(str)
    var x2: T
    s.read(x2)
    doAssert x2 == x
    # echo (x, x2)

  fun(234_560.int32)
  fun(234.int16)
  fun(0.int16)
  fun(12.uint8)
  fun(123123.int32)
  fun(123123.uint32)
  fun((-123).int8)
