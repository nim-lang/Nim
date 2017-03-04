discard """
  output: '''2 3'''
"""

# bug #4097

var i {.compileTime.} = 2

template defineId*(t: typedesc) =
  const id {.genSym.} = i
  static: inc(i)
  proc idFor*(T: typedesc[t]): int {.inline, raises: [].} = id

defineId(int8)
defineId(int16)

echo idFor(int8), " ", idFor(int16)
