discard """
  nimout: '''
tcallsitelineinfo2.nim(18, 1) Warning: abc [User]
tcallsitelineinfo2.nim(19, 12) Warning: def [User]
'''
  exitcode: 1
  outputsub: '''
tcallsitelineinfo2.nim(20) tcallsitelineinfo2
Error: unhandled exception: ghi [ValueError]
'''
"""

template foo(a: untyped): untyped {.callsite.} =
  {.warning: "abc".}
  a
  echo "hello"

foo: # with `{.line.}:`, the following do not keep their line information:
  {.warning: "def".}
  raise newException(ValueError, "ghi")
