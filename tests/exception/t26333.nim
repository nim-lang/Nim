discard """
  matrix: "--mm:refc; --mm:orc"
"""

# A failed call must not overwrite a local observed by finally or defer.
proc g(v: int): int =
  if v == 42:
    raise newException(ValueError, "x")
  v

proc checkFinally(v: int) =
  var y = 7
  try:
    y = g(v)
  finally:
    doAssert y == (if v == 42: 7 else: v)

proc checkDefer(v: int) =
  var y = 7
  defer:
    doAssert y == (if v == 42: 7 else: v)
  y = g(v)

for check in [checkFinally, checkDefer]:
  check(9)
  var caught = false
  try:
    check(42)
  except ValueError:
    caught = true
  doAssert caught
