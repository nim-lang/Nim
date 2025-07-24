discard """
  nimout: '''
tcallsitelineinfo.nim(17, 4) Warning: abc [User]
'''
  exitcode: 1
  outputsub: '''
tcallsitelineinfo.nim(17) tcallsitelineinfo
Error: unhandled exception: def [ValueError]
'''
"""

template foo(): untyped {.callsite.} =
  {.warning: "abc".}
  raise newException(ValueError, "def")
  echo "hello"

foo()
