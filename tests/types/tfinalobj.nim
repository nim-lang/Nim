discard """
  output: '''abc'''
"""

type
  TA = object {.pure, final.}
    x: string

var
  a: TA
a.x = "abc"

doAssert TA.sizeof == string.sizeof

echo a.x
