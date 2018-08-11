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
  ##   template test(x): typed =
  ##     echo "type: ", type(x), ", value: ", x
  ##
  ##   test 42
  ##   # --> type: int, value: 42
  ##   test "Foo"
  ##   # --> type: string, value: Foo
  ##   test(@['A','B'])
  ##   # --> type: seq[char], value: @[A, B]

proc `$`*(t: typedesc): string =
  ## An alias for `name`.
  name(t)

proc arity*(t: typedesc): int {.magic: "TypeTrait".}
  ## Returns the arity of the given type

proc genericHead*(t: typedesc): typedesc {.magic: "TypeTrait".}
  ## Accepts an instantiated generic type and returns its
  ## uninstantiated form.
  ##
  ## For example:
  ##   seq[int].genericHead will be just seq
  ##   seq[int].genericHead[float] will be seq[float]
  ##
  ## A compile-time error will be produced if the supplied type
  ## is not generic

proc stripGenericParams*(t: typedesc): typedesc {.magic: "TypeTrait".}
  ## This trait is similar to `genericHead`, but instead of producing
  ## error for non-generic types, it will just return them unmodified

proc supportsCopyMem*(t: typedesc): bool {.magic: "TypeTrait".}
  ## This trait returns true iff the type ``t`` is safe to use for
  ## `copyMem`:idx:. Other languages name a type like these `blob`:idx:.

proc sameType*(t1, t2: typedesc): bool =
  ## Returns wheter ``t1``, ``t2`` are the same type; this is different
  ## from expression ``a is b``
  runnableExamples:
    type T=int
    doAssert T.sameType(int)
    doAssert int.sameType(T)
    doAssert: not int.sameType(float)
  t1 is t2 and t2 is t1

when isMainModule:
  doAssert $type(42) == "int"
  discard sameType(int, int) ## pending https://github.com/nim-lang/Nim/issues/7280
