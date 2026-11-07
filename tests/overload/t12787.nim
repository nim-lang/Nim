discard """
  output: '''
42 1.5 true
int float
g
'''
"""

# bug #12787: generic routines that only differ in the constraints of their
# generic parameters are different overloads
import std/strutils
proc parse[T: int](s: string): T = parseInt(s)
proc parse[T: float](s: string): T = parseFloat(s)
proc parse[T: bool](s: string): T = parseBool(s)
echo parse[int]("42"), " ", parse[float]("1.5"), " ", parse[bool]("true")

proc f[T: int](x: T): string = "int"
proc f[T: float](x: T): string = "float"
echo f(1), " ", f(1.0)
proc g[T: int](x: T): string
proc g[T: int](x: T): string = "g"
echo g(3)
