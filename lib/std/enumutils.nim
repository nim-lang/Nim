#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import macros

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

const syntheticElemPrefix = "_sythetic_undefined_elem_"

proc intEnumWithHoles(enumBody: NimNode): NimNode =
  ## Fills the holes in an enum that has int or char values, with synthetic elems
  ## to benefit from making the enum an ordinal
  ## Only int values and with low sparsity, i.e. there cannot be an excesive number of
  ## holes as the ordinal would be grow with too many synthetic elements.
  if not (
    enumBody.kind == nnkStmtList and enumBody.len == 1 and
    enumBody[0].kind == nnkTypeSection and enumBody[0].len == 1 and
    enumBody[0][0][2].kind == nnkEnumTy):
     error("intEnumWithHoles: Expected an enum definition", enumBody)

  let typeDef = enumBody[0][0]
  let origEnum = typeDef[2]

  # To limit the growth of synthetic elements we limit it to sparsity ratio  to 5 times
  # the number of original elems.
  # Enums with to many holes and big int assignment are not a good fit for the Ordinal set.
  var maxAllowedSize = max(256, origEnum.len * 5)

  var elems: seq[NimNode]
  var nextOrd: int64 

  for i, e in origEnum:
    if i > 0: # Ignore first empty node
      if e.kind == nnkIdent:
        elems.add(e)
        inc(nextOrd) 

      elif e.kind == nnkEnumFieldDef:
        var ordValue: int64
        var lit: NimNode

        if e[1].kind == nnkPrefix and e[1][0] == ident("-"): # Negative numger
          lit = e[1][1]
          ordValue = -1 * lit.intVal
        else:
          lit = e[1]
          ordValue = lit.intVal

        if lit.kind notin nnkCharLit..nnkUInt64Lit:
          error("intEnumWithHoles: Only char are int values are allowed for the enum field values", e)

        if elems.len + (ordValue - nextOrd) > maxAllowedSize:
          error("intEnumWithHoles: Enum has too many holes. It is too sparse to efficiently convert to an Ordinal.")

        for holeIx in nextOrd..(ordValue - 1):
          elems.add newIdentNode(syntheticElemPrefix & $holeIx)

        elems.add e
        nextOrd = ordValue + 1

  typeDef[2] = newNimNode(nnkEnumTy).add(newEmptyNode()).add(elems)
  result = enumBody

macro intEnumWithHoles*(body: untyped): untyped =
  result = intEnumWithHoles(body)

proc isDefined*[A: Ordinal](a: A): bool =
  ## Check whether a is defined in an enum with Holes
  $a != syntheticElemPrefix & $ord(a)

iterator definedItems*(E: typedesc[enum]): E {.inline.} =
  ## Filters out synthetic elements covering holes in enums with int values
  ## crated by macro intEnumWithHoles
  for e in items(E):
    if isDefined(e):
      yield e

