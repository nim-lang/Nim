##[

# This is now a header

## Next header

### And so on

# More headers

###### Up to level 6


#. An enumeration
#. Second idea here.

More text.

1. Other case value
2. Second case.

]##

type
  SomeType* = enum
    enumValueA,
    enumValueB,
    enumValueC

proc someType*(): SomeType =
  ## constructor.
  SomeType(2)

# bug #9235

template aEnum*(): untyped =
  type
    A* {.inject.} = enum ## The enum A.
      aA

template bEnum*(): untyped =
  type
    B* {.inject.} = enum ## The enum B.
      bB

  func someFunc*() =
    ## My someFunc.
    ## Stuff in `quotes` here.
    ## [Some link](https://nim-lang.org)
    discard
