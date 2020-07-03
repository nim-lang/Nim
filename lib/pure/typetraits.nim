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
##
## Unstable API.

import std/private/since
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
  ##       type MatchedGenericType = genericHead(typeof(f))
  ##         # `f` will be a value of a type such as `Option[T]`
  ##         # `MatchedGenericType` will become the `Option` type


proc stripGenericParams*(t: typedesc): typedesc {.magic: "TypeTrait".}
  ## This trait is similar to `genericHead <#genericHead,typedesc>`_, but
  ## instead of producing error for non-generic types, it will just return
  ## them unmodified.

proc supportsCopyMem*(t: typedesc): bool {.magic: "TypeTrait".}
  ## This trait returns true if the type ``t`` is safe to use for
  ## `copyMem`:idx:.
  ##
  ## Other languages name a type like these `blob`:idx:.

proc isNamedTuple*(T: typedesc): bool {.magic: "TypeTrait".}
  ## Return true for named tuples, false for any other type.

proc distinctBase*(T: typedesc): typedesc {.magic: "TypeTrait".}
  ## Returns base type for distinct types, works only for distinct types.
  ## compile time error otherwise

since (1, 1):
  template distinctBase*[T](a: T): untyped =
    ## overload for values
    runnableExamples:
      type MyInt = distinct int
      doAssert 12.MyInt.distinctBase == 12
    distinctBase(type(a))(a)

  proc tupleLen*(T: typedesc[tuple]): int {.magic: "TypeTrait".}
    ## Return number of elements of `T`

  template tupleLen*(t: tuple): int =
    ## Return number of elements of `t`
    tupleLen(type(t))

  template get*(T: typedesc[tuple], i: static int): untyped =
    ## Return `i`\th element of `T`
    # Note: `[]` currently gives: `Error: no generic parameters allowed for ...`
    type(default(T)[i])

  type StaticParam*[value: static type] = object
    ## used to wrap a static value in `genericParams`

since (1, 3, 5):
  template elementType*(a: untyped): typedesc =
    ## return element type of `a`, which can be any iterable (over which you
    ## can iterate)
    runnableExamples:
      iterator myiter(n: int): auto =
        for i in 0..<n: yield i
      doAssert elementType(@[1,2]) is int
      doAssert elementType("asdf") is char
      doAssert elementType(myiter(3)) is int
    typeof(block: (for ai in a: ai))

import std/macros

macro genericParamsImpl(T: typedesc): untyped =
  # auxiliary macro needed, can't do it directly in `genericParams`
  result = newNimNode(nnkTupleConstr)
  var impl = getTypeImpl(T)
  expectKind(impl, nnkBracketExpr)
  impl = impl[1]
  while true:
    case impl.kind
      of nnkSym:
        impl = impl.getImpl
        continue
      of nnkTypeDef:
        impl = impl[2]
        continue
      of nnkTypeOfExpr:
        impl = getTypeInst(impl[0])
        continue
      of nnkBracketExpr:
        for i in 1..<impl.len:
          let ai = impl[i]
          var ret: NimNode = nil
          case ai.typeKind
          of ntyTypeDesc:
            ret = ai
          of ntyStatic: doAssert false
          else:
            # getType from a resolved symbol might return a typedesc symbol.
            # If so, use it directly instead of wrapping it in StaticParam.
            if (ai.kind == nnkSym and ai.symKind == nskType) or
               (ai.kind == nnkBracketExpr and ai[0].kind == nnkSym and
                ai[0].symKind == nskType):
              ret = ai
            elif ai.kind == nnkInfix and ai[0].kind == nnkIdent and
                 ai[0].strVal == "..":
              # For built-in array types, the "2" is translated to "0..1" then
              # automagically translated to "range[0..1]". However this is not
              # reflected in the AST, thus requiring manual transformation here.
              #
              # We will also be losing some context here:
              #   var a: array[10, int]
              # will be translated to:
              #   var a: array[0..9, int]
              # after typecheck. This means that we can't get the exact
              # definition as typed by the user, which will cause confusion for
              # users expecting:
              #   genericParams(typeof(a)) is (StaticParam(10), int)
              # to be true while in fact the result will be:
              #   genericParams(typeof(a)) is (range[0..9], int)
              ret = newTree(nnkBracketExpr, @[bindSym"range", ai])
            else:
              since (1, 1):
                ret = newTree(nnkBracketExpr, @[bindSym"StaticParam", ai])
          result.add ret
        break
      else:
        error "wrong kind: " & $impl.kind, impl

since (1, 1):
  template genericParams*(T: typedesc): untyped =
    ## return tuple of generic params for generic `T`
    runnableExamples:
      type Foo[T1, T2] = object
      doAssert genericParams(Foo[float, string]) is (float, string)
      type Bar[N: static float, T] = object
      doAssert genericParams(Bar[1.0, string]) is (StaticParam[1.0], string)
      doAssert genericParams(Bar[1.0, string]).get(0).value == 1.0
      doAssert genericParams(seq[Bar[2.0, string]]).get(0) is Bar[2.0, string]
      var s: seq[Bar[3.0, string]]
      doAssert genericParams(typeof(s)) is (Bar[3.0, string],)

      # NOTE: For the builtin array type, the index generic param will
      #       **always** become a range type after it's bound to a variable.
      doAssert genericParams(array[10, int]) is (StaticParam[10], int)
      var a: array[10, int]
      doAssert genericParams(typeof(a)) is (range[0..9], int)

    type T2 = T
    genericParamsImpl(T2)
