discard """
  action: reject
  nimout: '''
stack trace: (most recent call last)
tvmranges.nim(14, 10)
tvmranges.nim(14, 10) Error: unhandled exception: value out of range
'''
"""

type X = enum
  a
  b

when pred(a) == b:
  echo "a"
else:
  echo "b"