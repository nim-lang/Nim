discard """
  cmd: "nim $target $options --excessiveStackTrace:off $file"
  output: '''
test:ok
'''
"""
import testhelper
try:
  doAssert(false, "msg")
except AssertionError as e:
  checkMsg(e.msg, "trelativeassert.nim(9, 11) `false` msg", "test", false)
