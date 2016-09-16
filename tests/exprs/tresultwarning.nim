discard """
  nimout: "Special variable 'result' is shadowed."
"""

proc test(): string =
  var result = "foo"
