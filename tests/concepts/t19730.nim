discard """
  output: '''1.01.01.01.0
1.01.01.01.0
'''
"""

type
  Color = concept c
    c.r is SomeFloat
    c.g is SomeFloat
    c.b is SomeFloat
    c.a is SomeFloat

proc useColor(color: Color) =
  echo(color.r, color.g, color.b, color.a)

let color = (r: 1.0, g: 1.0, b: 1.0, a: 1.0)
useColor(color)

useColor((r: 1.0, g: 1.0, b: 1.0, a: 1.0))
