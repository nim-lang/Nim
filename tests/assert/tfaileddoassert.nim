discard """
  cmd: "nim $target -d:release $options $file"
  output: '''
true
MOCKEDFILE `a == 3` bar
'''
"""

from strutils import endsWith, split

onFailedAssert(msg):
  echo msg.endsWith("tfaileddoassert.nim(15, 9) `a == 2` foo")

var a = 1
doAssert(a == 2, "foo")

onFailedAssert(msg):
  echo msg
doAssert(a == 3, "bar", "MOCKEDFILE")
