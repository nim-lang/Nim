discard """
  cmd: "nim $target $options --stackTrace:on --lineTrace:on $file"
  outputsub: '''
t7224.aaa, line: 21
t7224.bbb, line: 18
t7224.ccc, line: 15
t7224.ddd, line: 12
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
