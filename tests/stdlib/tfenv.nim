import fenv


func is_significant(x: float): bool =
  if x > minimumPositiveValue(float) and x < maximumPositiveValue(float): true
  else: false

doAssert is_significant(10.0)
