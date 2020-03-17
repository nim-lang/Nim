discard """
  output: '''
before
swallowed
before
swallowed B
'''
  cmd: "nim c --gc:arc --exceptions:goto $file"
"""

# bug #13599
proc main() =
  try:
    echo "before"
    raise newException(CatchableError, "foo")
  except AssertionError:
    echo "caught"
  echo "after"

try:
  main()
except:
  echo "swallowed"

proc mainB() =
  try:
    echo "before"
    raise newException(CatchableError, "foo")
  # except CatchableError: # would work
  except AssertionError:
    echo "caught"
  except:
    raise
  echo "after"

try:
  mainB()
except:
  echo "swallowed B"
