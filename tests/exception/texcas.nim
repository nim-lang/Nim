discard """
  output: '''Hello'''
"""

try:
  raise newException(Exception, "Hello")
except Exception as foobar:
  echo(foobar.msg)


