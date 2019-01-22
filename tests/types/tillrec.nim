discard """
  errormsg: "illegal recursion in type \'TIllegal\'"
  file: "tillrec.nim"
  line: 13
"""
# test illegal recursive types

type
  TLegal {.final.} = object
    x: int
    kids: seq[TLegal]

  TIllegal {.final.} = object  #ERROR_MSG illegal recursion in type 'TIllegal'
    y: int
    x: array[0..3, TIllegal]
