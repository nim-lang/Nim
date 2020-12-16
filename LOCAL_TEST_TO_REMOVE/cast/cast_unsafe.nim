discard """
action: compile
"""

proc xx(x: int) : float =
  result = cast[float](x)

proc yy() =
  var x = 123456789
  echo xx(x)

yy()
