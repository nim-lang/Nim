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

runnableExamples:
  discard "module level 1"

when true:
  runnableExamples:
    discard "module level 2"
  runnableExamples:
    discard "module level 3"

## before 4
runnableExamples:
  discard "module level 4"
## after 4

type
  SomeType* = enum
    enumValueA,
    enumValueB,
    enumValueC

proc someType*(): SomeType =
  ## constructor.
  SomeType(2)


proc fn2*() = discard ## comment
proc fn3*(): auto = 1 ## comment
proc fn4*(): auto = 2 * 3 + 4 ## comment
proc fn5*() ## comment
proc fn5*() = discard
proc fn6*() =
  ## comment
proc fn7*() =
  ## comment
  discard
proc fn8*(): auto =
  ## comment
  1+1
func fn9*(a: int): int = 42  ## comment
func fn10*(a: int): int = a  ## comment

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
  ## should be shown in utils.html only
  runnableExamples:
    discard "should be in utils.html only, not in module that calls fromUtilsGen"
  ## ditto

  iterator fromUtils1*(): int =
    runnableExamples:
      # ok1
      assert 1 == 1
      # ok2
    yield 15

  template fromUtils2*() =
    ## ok3
    runnableExamples:
      discard """should be shown as examples for fromUtils2
       in module calling fromUtilsGen"""

  proc fromUtils3*() =
    ## came form utils but should be shown where `fromUtilsGen` is called
    runnableExamples: discard """should be shown as examples for fromUtils3
       in module calling fromUtilsGen"""

# bug #18305
var
  c1*, c2*: int ## comment1
  c3*: int ## comment3
runnableExamples:
  discard "ok1"
runnableExamples:
  discard "ok2"
## ok3
runnableExamples:
  discard "ok4"
## ok5

## ok6
## ok7
runnableExamples:
  discard "ok8"

type
  Foo1* = object
  Foo2* = object
## ok1
runnableExamples:
  discard "ok2"
## ok3

let c4* = 1
runnableExamples:
  discard "ok1"

let c5* = 1
## ok1

let c6* = 1 ## ok1

const c7* = 1
runnableExamples:
  discard "ok1"

const
  c8* = 1
  c9* = 1
runnableExamples:
  discard "ok1"

when 1+1 == 2:
  type Foo3* = object
  runnableExamples:
    discard "ok for Foo3"

# closes https://github.com/nim-lang/RFCs/issues/309
proc gn1*()
runnableExamples:
  discard "gn1"

proc gn2*()
  ## ok1
runnableExamples:
  discard "gn2"

proc gn1() = discard
proc gn2() = discard

when true:
  proc gn3*()
  runnableExamples:
    discard "gn3"
  proc gn3() = discard

proc gn4*()
runnableExamples:
  discard "gn4"
proc gn4() = discard

when true:
  proc gn5*()
  runnableExamples:
    discard "gn5" # works even if implementation is in an include

include utils_incl
