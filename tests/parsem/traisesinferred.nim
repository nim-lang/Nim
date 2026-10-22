discard """
  matrix: "--parsem:on"
  errormsg: "callee() can raise an unlisted exception: ref ValueError"
  line: 9
"""

# The effects of a routine declared further down are inferred, not assumed:

proc caller() {.raises: [].} = callee()

proc callee() =
  raise newException(ValueError, "x")

caller()
