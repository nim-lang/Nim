# test illegal recursive types

type
  TLegal = record
    x: int
    kids: seq[TLegal]

  TIllegal = record
    y: Int
    x: array[0..3, TIllegal]
  #ERROR_MSG illegal recursion in type 'TIllegal'

