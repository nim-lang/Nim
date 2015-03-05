discard """
  msg: "Special variable 'result' is shadowed. [ResultShadowed]"
  line: 7
"""

proc test(): string =
  var result = "foo"
