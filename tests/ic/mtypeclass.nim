# Helper for ttypeclass.nim: a type that participates in a concept match
# from another module. Under `nim ic`, concept/`is` matching used to walk
# a Partial `tyTypeDesc` stub's empty `sonsImpl` (`skipTypeCursor` in
# typeRel) and raise IndexDefect.

type
  Foo* = object
    x*: int
