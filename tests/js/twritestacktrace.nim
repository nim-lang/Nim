discard """
  cmd: "nim js --panics:on $file"
  output: '''Traceback (most recent call last)
twritestacktrace.nim(12) at module twritestacktrace
twritestacktrace.nim(10) at twritestacktrace.hello
'''
"""

proc hello() =
  writeStackTrace()

hello()
