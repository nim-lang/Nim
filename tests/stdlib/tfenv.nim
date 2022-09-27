import std/fenv
import std/assertions


func is_significant(x: float): bool =
  x > minimumPositiveValue(float) and x < maximumPositiveValue(float)

doAssert is_significant(10.0)
