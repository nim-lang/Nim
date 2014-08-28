#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module defines compile-time reflection procs for
## working with types

proc name*(t: typedesc): string {.magic: "TypeTrait".}
  ## Returns the name of the given type.
  ##
  ## Example:
  ##
  ## .. code-block::
  ##
  ##   import typetraits
  ##
  ##   proc `$`*[T](some:typedesc[T]): string = name(T)
  ##
  ##   template test(x): stmt =
  ##     echo "type: ", type(x), ", value: ", x
  ##
  ##   test 42
  ##   # --> type: int, value: 42
  ##   test "Foo"
  ##   # --> type: string, value: Foo
  ##   test(@['A','B'])
  ##   # --> type: seq[char], value: @[A, B]


proc arity*(t: typedesc): int {.magic: "TypeTrait".}
  ## Returns the arity of the given type
