discard """
  output: '''test
test'''
"""
# bug #4537

# nim js -d:nodejs

type
  Str = distinct string

when true:
  # crashes
  converter convert(s: string | cstring): Str = Str($s)
else:
  # works!
  converter convert(s: string): Str = Str($s)
  converter convert(s: cstring): Str = Str($s)

proc echoStr(s: Str) = echo s.string

echoStr("test")
echoStr("test".cstring)
