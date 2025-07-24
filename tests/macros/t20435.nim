
#[
  A better test requires matching, so the use of @ working can be showcased
  For example:

  proc regularCase[T]() = 
    case [(1, 3), (3, 4)]:
    of [(1, @a), (_, @b)]:
      echo a, b
    else: discard
]#

{.experimental: "caseStmtMacros".}

import macros

type Foo = object

macro `case`(obj: Foo) = quote do: discard

proc notGeneric() =
  case Foo()
  of a b c d: discard

proc generic[T]() =
  case Foo()
  of a b c d: discard

notGeneric()
generic[int]()
