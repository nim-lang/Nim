discard """
  nimout: "Special variable 'result' is shadowed. [ResultShadowed]"
"""

proc test(): string =
  var result = "foo"
