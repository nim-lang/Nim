# test illegal recursive types

type
  TLegal {.final.} = object
    x: int
    kids: seq[TLegal]

  TIllegal {.final.} = object  #ERROR_MSG illegal recursion in type 'TIllegal'
    y: Int
    x: array[0..3, TIllegal]
