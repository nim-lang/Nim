discard """
  cmd: "nim c -d:nimStacktraceOverride $file"
  output: '''begin
Traceback (most recent call last, using override)
Error: unhandled exception: stack trace produced [ValueError]
'''
  exitcode: 1
"""

import asyncfutures

proc main =
  echo "begin"
  if true:
    raise newException(ValueError, "stack trace produced")
  echo "unreachable"

main()
