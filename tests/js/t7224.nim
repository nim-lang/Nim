discard """
  cmd: "nim $target $options --stackTrace:on --lineTrace:on $file"
  outputsub: '''
t7224.nim(25) at module t7224
t7224.nim(22) at t7224.aaa
t7224.nim(19) at t7224.bbb
t7224.nim(16) at t7224.ccc
t7224.nim(13) at t7224.ddd
'''
"""

proc ddd() =
  raise newException(IOError, "didn't do stuff")

proc ccc() =
  ddd()

proc bbb() =
  ccc()

proc aaa() =
  bbb()

try:
  aaa()

except IOError as e:
  echo getStackTrace(e)
