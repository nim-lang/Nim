discard """
  matrix: "--warning:systemRangeConversion --warningaserror:systemRangeConversion"
  action: "reject"
  errormsg: "implicit range conversion int literal(12) -> Natural"
"""


proc foo(x: Natural) =
  discard

foo(12)