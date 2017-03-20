
# just ensure this keeps compiling:

import macros

proc error(s: string) = quit s

macro assertOrReturn*(condition: bool; message: string): typed =
  var line = condition.lineInfo()
  result = quote do:
    block:
      if not likely(`condition`):
        error("Assertion failed: " & $(`message`) & "\n" & `line`)
        return

macro assertOrReturn*(condition: bool): typed =
  var message = condition.toStrLit()
  result = getAst assertOrReturn(condition, message)

proc point*(size: int16): tuple[x, y: int16] =
  # returns random point in square area with given `size`

  assertOrReturn size > 0
