discard """
  cmd: "nim c --exceptions:setjmp $file"
  exitcode: 1
  output: '''
t26189.nim(20)           t26189
t26189.nim(18)           trigger
Error: unhandled exception: rollback failed [CatchableError]
'''
"""

# Regression test for compiler recursion while generating a raise in finally.
proc trigger() =
  try:
    discard
  except Exception as exc:
    raise exc
  finally:
    raise newException(CatchableError, "rollback failed")

trigger()
