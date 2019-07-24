#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module defines compile-time reflection procs for
## working with types.

export system.`$` # for backward compatibility


proc name*(t: typedesc): string {.magic: "TypeTrait".}
  ## Returns the name of the given type.
  ##
  ## Alias for system.`$`(t) since Nim v0.20.

proc arity*(t: typedesc): int {.magic: "TypeTrait".} =
  ## Returns the arity of the given type. This is the number of "type"
  ## components or the number of generic parameters a given type ``t`` has.
  runnableExamples:
    assert arity(seq[string]) == 1
    assert arity(array[3, int]) == 2
    assert arity((int, int, float, string)) == 4

proc genericHead*(t: typedesc): typedesc {.magic: "TypeTrait".}
  ## Accepts an instantiated generic type and returns its
  ## uninstantiated form.
  ##
  ## For example:
  ## * `seq[int].genericHead` will be just `seq`
  ## * `seq[int].genericHead[float]` will be `seq[float]`
  ##
  ## A compile-time error will be produced if the supplied type
  ## is not generic.
  ##
  ## See also:
  ## * `stripGenericParams <#stripGenericParams,typedesc>`_
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   type
  ##     Functor[A] = concept f
  ##       type MatchedGenericType = genericHead(f.type)
  ##         # `f` will be a value of a type such as `Option[T]`
  ##         # `MatchedGenericType` will become the `Option` type


proc stripGenericParams*(t: typedesc): typedesc {.magic: "TypeTrait".}
  ## This trait is similar to `genericHead <#genericHead,typedesc>`_, but
  ## instead of producing error for non-generic types, it will just return
  ## them unmodified.

proc supportsCopyMem*(t: typedesc): bool {.magic: "TypeTrait".}
  ## This trait returns true iff the type ``t`` is safe to use for
  ## `copyMem`:idx:.
  ##
  ## Other languages name a type like these `blob`:idx:.

proc isNamedTuple*(T: typedesc): bool =
  ## Return true for named tuples, false for any other type.
  when T isnot tuple: result = false
  else:
    var t: T
    for name, _ in t.fieldPairs:
      when name == "Field0":
        return compiles(t.Field0)
      else:
        return true
    # empty tuple should be un-named,
    # see https://github.com/nim-lang/Nim/issues/8861#issue-356631191
    return false


when isMainModule:
  static:
    doAssert $type(42) == "int"
    doAssert int.name == "int"

  const a1 = name(int)
  const a2 = $(int)
  const a3 = $int
  doAssert a1 == "int"
  doAssert a2 == "int"
  doAssert a3 == "int"

  proc fun[T: typedesc](t: T) =
    const a1 = name(t)
    const a2 = $(t)
    const a3 = $t
    doAssert a1 == "int"
    doAssert a2 == "int"
    doAssert a3 == "int"
  fun(int)
