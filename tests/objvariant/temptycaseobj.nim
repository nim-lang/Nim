discard """
  line: 11
  errormsg: "identifier expected, but got 'keyword of'"
"""

type
  TMyEnum = enum enA, enU, enO
  TMyCase = object
    case e: TMyEnum
    of enA:
    of enU: x, y: int
    of enO: a, b: string


