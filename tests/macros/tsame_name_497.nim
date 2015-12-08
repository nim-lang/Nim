discard """
  file: "tsame_name_497.nim"
  disabled: "true"
"""

import macro_bug

type TObj = object

proc f(o: TObj) {.macro_bug.} = discard
