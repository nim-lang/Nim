discard """
  errormsg: "invalid indentation"
  line: 10
  column: 14
"""

type
  A = (object | tuple | int)
  B = int | object | tuple
  C = object | tuple | int # issue #8846
