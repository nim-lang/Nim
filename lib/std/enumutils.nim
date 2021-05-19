#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import macros
from typetraits import OrdinalEnum, HoleyEnum

# xxx `genEnumCaseStmt` needs tests and runnableExamples

macro genEnumCaseStmt*(typ: typedesc, argSym: typed, default: typed,
            userMin, userMax: static[int], normalizer: static[proc(s :string): string]): untyped =
  # generates a case stmt, which assigns the correct enum field given
  # a normalized string comparison to the `argSym` input.
  # string normalization is done using passed normalizer.
  # NOTE: for an enum with fields Foo, Bar, ... we cannot generate
  # `of "Foo".nimIdentNormalize: Foo`.
  # This will fail, if the enum is not defined at top level (e.g. in a block).
  # Thus we check for the field value of the (possible holed enum) and convert
  # the integer value to the generic argument `typ`.
  let typ = typ.getTypeInst[1]
  let impl = typ.getImpl[2]
  expectKind impl, nnkEnumTy
  let normalizerNode = quote: `normalizer`
  expectKind normalizerNode, nnkSym
  result = nnkCaseStmt.newTree(newCall(normalizerNode, argSym))
  # stores all processed field strings to give error msg for ambiguous enums
  var foundFields: seq[string] = @[]
  var fStr = "" # string of current field
  var fNum = BiggestInt(0) # int value of current field
  for f in impl:
    case f.kind
    of nnkEmpty: continue # skip first node of `enumTy`
    of nnkSym, nnkIdent: fStr = f.strVal
    of nnkEnumFieldDef:
      case f[1].kind
      of nnkStrLit: fStr = f[1].strVal
      of nnkTupleConstr:
        fStr = f[1][1].strVal
        fNum = f[1][0].intVal
      of nnkIntLit:
        fStr = f[0].strVal
        fNum = f[1].intVal
      else: error("Invalid tuple syntax!", f[1])
    else: error("Invalid node for enum type!", f)
    # add field if string not already added
    if fNum >= userMin and fNum <= userMax:
      fStr = normalizer(fStr)
      if fStr notin foundFields:
        result.add nnkOfBranch.newTree(newLit fStr,  nnkCall.newTree(typ, newLit fNum))
        foundFields.add fStr
      else:
        error("Ambiguous enums cannot be parsed, field " & $fStr &
          " appears multiple times!", f)
    inc fNum
  # finally add else branch to raise or use default
  if default == nil:
    let raiseStmt = quote do:
      raise newException(ValueError, "Invalid enum value: " & $`argSym`)
    result.add nnkElse.newTree(raiseStmt)
  else:
    expectKind(default, nnkSym)
    result.add nnkElse.newTree(default)

macro enumFullRange(a: typed): untyped =
  newNimNode(nnkCurly).add(a.getType[1][1..^1])

macro enumNames(a: typed): untyped =
  # this could be exported too; in particular this could be useful for enum with holes.
  result = newNimNode(nnkBracket)
  for ai in a.getType[1][1..^1]:
    assert ai.kind == nnkSym
    result.add newLit ai.strVal

iterator items*[T: HoleyEnum](E: typedesc[T]): T =
  ## Iterates over an enum with holes.
  runnableExamples:
    type A = enum a0 = 2, a1 = 4, a2
    type B[T] = enum b0 = 2, b1 = 4
    from std/sequtils import toSeq
    assert A.toSeq == [a0, a1, a2]
    assert B[float].toSeq == [B[float].b0, B[float].b1]
  for a in enumFullRange(E): yield a

import std/private/lookuptables

func symbolRankImpl[T](a: T): int {.inline.} =
  const lut = (proc(): auto = # pending https://github.com/nim-lang/RFCs/issues/276
    var a: seq[int]
    for ai in items(T): a.add ai.ord
    a.initLookupTable)()
  let lut2 {.global.} = lut
    # xxx improve pending https://github.com/timotheecour/Nim/issues/553
  {.noSideEffect.}: # because it's immutable
    let ret = lut2.lookup(a.ord)
  if ret != -1: return ret
  raise newException(IndexDefect, $ord(a) & " invalid for " & $T)

template symbolRank*[T: enum](a: T): int =
  ## Returns the index in which `a` is listed in `T` with `O(1)` cost even
  ## for `HoleyEnum`.
  # The `O(1)` cost for `HoleyEnum` should hold except for adverserially designed
  # holey enums; if that becomes a problem we could fix it by optimizing over
  # `lookuptables.pseudoRandomMixing` since `T` is known at CT.
  runnableExamples:
    type
      A = enum a0 = -3, a1 = 10, a2, a3 = (20, "f3Alt") # HoleyEnum
      B = enum b0, b1, b2 # OrdinalEnum
      C = enum c0 = 10, c1, c2 # OrdinalEnum
    assert a2.symbolRank == 2
    assert b2.symbolRank == 2
    assert c2.symbolRank == 2
    assert c2.ord == 12
    assert a2.ord == 11
    var invalid = 7.A
    doAssertRaises(IndexDefect): discard invalid.symbolRank
  when T is Ordinal: ord(a) - T.low.ord.static
  else: symbolRankImpl(a)

func symbolName*[T: enum](a: T): string =
  ## Returns the symbol name of an enum.
  runnableExamples:
    type B = enum
      b0 = (10, "kb0")
      b1 = "kb1"
      b2
    let b = B.low
    assert b.symbolName == "b0"
    assert $b == "kb0"
    static: assert B.high.symbolName == "b2"
    type C = enum c0 = -3, c1 = 4, c2 = 20 # HoleyEnum
    assert c1.symbolName == "c1"
  const names = enumNames(T)
  names[a.symbolRank]
