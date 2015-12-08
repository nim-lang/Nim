discard """
  file: "tauto_canbe_void.nim"
"""

import future

template tempo(s: expr) =
  s("arg")

tempo((s: string)->auto => echo(s))
tempo((s: string) => echo(s))
