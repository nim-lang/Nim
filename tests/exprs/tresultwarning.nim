discard """
  nimout: "tresultwarning.nim(6, 7) Warning: Special variable 'result' is shadowed. [ResultShadowed]"
"""

proc test(): string =
  var result = "foo"
