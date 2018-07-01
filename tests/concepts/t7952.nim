discard """
  output: 5
"""

type
  HasLen = concept iter
    len(iter) is int

proc echoLen(x: HasLen) =
  echo len(x)

echoLen([1, 2, 3, 4, 5])
