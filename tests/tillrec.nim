# test illegal recursive types

type
  TLegal {.final.} = object
    x: int
    kids: seq[TLegal]

  TIllegal {.final.} = object
    y: Int
    x: array[0..3, TIllegal]
  #ERROR_MSG illegal recursion in type 'TIllegal'

