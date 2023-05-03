discard """
  output: '''abc'''
"""

type
  TA {.pure, final.} = object
    x: string

var
  a: TA
a.x = "abc"

doAssert TA.sizeof == string.sizeof

echo a.x
