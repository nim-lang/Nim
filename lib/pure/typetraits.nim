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
  ##   proc `$`*(T: typedesc): string = name(T)
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

proc GenericHead*(t: typedesc): typedesc {.magic: "TypeTrait".}
  ## Accepts an instantiated generic type and returns its
  ## uninstantiated form.
  ##
  ## For example:
  ##   seq[int].GenericHead will be just seq
  ##   seq[int].GenericHead[float] will be seq[float]
  ##
  ## A compile-time error will be produced if the supplied type
  ## is not generic

proc StripGenericParams*(t: typedesc): typedesc {.magic: "TypeTrait".}
  ## This trait is similar to `GenericHead`, but instead of producing
  ## error for non-generic types, it will just return them unmodified

