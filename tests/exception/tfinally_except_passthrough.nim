discard """
  matrix: "--mm:orc; --mm:refc; --mm:orc -d:release"
  output: '''
caught boom
caught boom in a loop
caught boom in a branch
'''
"""

# An exception that passes through a `finally` must not be caught by an
# `except` branch inside that `finally`, even when the `try` body there is
# known not to raise.

proc noop() = discard

proc direct(): int =
  try:
    raise newException(ValueError, "boom")
  finally:
    try:
      noop()
    except CatchableError:
      discard

proc inLoop(): int =
  try:
    raise newException(ValueError, "boom in a loop")
  finally:
    for i in 0..1:
      try:
        noop()
      except CatchableError:
        discard

proc inBranch(flag: bool): int =
  try:
    raise newException(ValueError, "boom in a branch")
  finally:
    if flag:
      try:
        noop()
      except ValueError:
        discard

for p in [direct, inLoop, proc (): int = inBranch(true)]:
  try:
    echo "returned normally: ", p()
  except ValueError as e:
    echo "caught ", e.msg
