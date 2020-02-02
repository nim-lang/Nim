discard """
  cmd: "nim $target -d:release $options $file"
  output: '''
test1:ok
test2:ok
'''
"""

import testhelper

onFailedAssert(msg):
  checkMsg(msg, "tdoassert.nim(15, 9) `a == 2` foo", "test1")

var a = 1
doAssert(a == 2, "foo")

onFailedAssert(msg):
  checkMsg(msg, "tdoassert.nim(20, 10) `a == 3` ", "test2")

doAssert a == 3
