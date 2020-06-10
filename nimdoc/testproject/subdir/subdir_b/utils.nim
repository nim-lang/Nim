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

# BUG: module link in theindex.html is wrong, see #14434

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

template fromUtilsGen*(): untyped =
  ## this should be shown in utils.html
  runnableExamples:
    assert 3*2 == 6
  ## ditto

  iterator fromUtils1*(): int =
    runnableExamples:
      # ok1
      assert 1 == 1
      # ok2
    yield 15

  template fromUtils2*() =
    ## ok3

  proc fromUtils3*() =
    ## came form utils but should be shown where `fromUtilsGen` is called
    runnableExamples: discard 1
