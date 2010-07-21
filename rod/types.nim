#
#
#           The Nimrod Compiler
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# this module contains routines for accessing and iterating over types

import 
  ast, astalgo, trees, msgs, strutils, platform

proc firstOrd*(t: PType): biggestInt
proc lastOrd*(t: PType): biggestInt
proc lengthOrd*(t: PType): biggestInt
type 
  TPreferedDesc* = enum 
    preferName, preferDesc

proc TypeToString*(typ: PType, prefer: TPreferedDesc = preferName): string
proc getProcHeader*(sym: PSym): string
proc base*(t: PType): PType
  # ------------------- type iterator: ----------------------------------------
type 
  TTypeIter* = proc (t: PType, closure: PObject): bool # should return true if the iteration should stop
  TTypeMutator* = proc (t: PType, closure: PObject): PType # copy t and mutate it
  TTypePredicate* = proc (t: PType): bool

proc IterOverType*(t: PType, iter: TTypeIter, closure: PObject): bool
  # Returns result of `iter`.
proc mutateType*(t: PType, iter: TTypeMutator, closure: PObject): PType
  # Returns result of `iter`.
proc SameType*(x, y: PType): bool
proc SameTypeOrNil*(a, b: PType): bool
proc equalOrDistinctOf*(x, y: PType): bool
type 
  TParamsEquality* = enum     # they are equal, but their
                              # identifiers or their return
                              # type differ (i.e. they cannot be
                              # overloaded)
                              # this used to provide better error messages
    paramsNotEqual,           # parameters are not equal
    paramsEqual,              # parameters are equal
    paramsIncompatible

proc equalParams*(a, b: PNode): TParamsEquality
  # returns whether the parameter lists of the procs a, b are exactly the same
proc isOrdinalType*(t: PType): bool
proc enumHasWholes*(t: PType): bool
const 
  abstractPtrs* = {tyVar, tyPtr, tyRef, tyGenericInst, tyDistinct, tyOrdinal}
  abstractVar* = {tyVar, tyGenericInst, tyDistinct, tyOrdinal}
  abstractRange* = {tyGenericInst, tyRange, tyDistinct, tyOrdinal}
  abstractVarRange* = {tyGenericInst, tyRange, tyVar, tyDistinct, tyOrdinal}
  abstractInst* = {tyGenericInst, tyDistinct, tyOrdinal}

proc skipTypes*(t: PType, kinds: TTypeKinds): PType
proc elemType*(t: PType): PType
proc containsObject*(t: PType): bool
proc containsGarbageCollectedRef*(typ: PType): bool
proc containsHiddenPointer*(typ: PType): bool
proc canFormAcycle*(typ: PType): bool
proc isCompatibleToCString*(a: PType): bool
proc getOrdValue*(n: PNode): biggestInt
proc computeSize*(typ: PType): biggestInt
proc getSize*(typ: PType): biggestInt
proc isPureObject*(typ: PType): bool
proc inheritanceDiff*(a, b: PType): int
  # | returns: 0 iff `a` == `b`
  # | returns: -x iff `a` is the x'th direct superclass of `b`
  # | returns: +x iff `a` is the x'th direct subclass of `b`
  # | returns: `maxint` iff `a` and `b` are not compatible at all
proc InvalidGenericInst*(f: PType): bool
  # for debugging
type 
  TTypeFieldResult* = enum 
    frNone,                   # type has no object type field 
    frHeader,                 # type has an object type field only in the header
    frEmbedded                # type has an object type field somewhere embedded

proc analyseObjectWithTypeField*(t: PType): TTypeFieldResult
  # this does a complex analysis whether a call to ``objectInit`` needs to be
  # made or intializing of the type field suffices or if there is no type field
  # at all in this type.
proc typeAllowed*(t: PType, kind: TSymKind): bool
# implementation

proc InvalidGenericInst(f: PType): bool = 
  result = (f.kind == tyGenericInst) and (lastSon(f) == nil)

proc inheritanceDiff(a, b: PType): int = 
  # conversion to superclass?
  var x = a
  result = 0
  while (x != nil): 
    if x.id == b.id: return 
    x = x.sons[0]
    dec(result)
  var y = b
  result = 0
  while (y != nil): 
    if y.id == a.id: return 
    y = y.sons[0]
    inc(result)
  result = high(int)

proc isPureObject(typ: PType): bool = 
  var t: PType
  t = typ
  while t.sons[0] != nil: t = t.sons[0]
  result = (t.sym != nil) and (sfPure in t.sym.flags)

proc getOrdValue(n: PNode): biggestInt = 
  case n.kind
  of nkCharLit..nkInt64Lit: result = n.intVal
  of nkNilLit: result = 0
  else: 
    liMessage(n.info, errOrdinalTypeExpected)
    result = 0

proc isCompatibleToCString(a: PType): bool = 
  result = false
  if a.kind == tyArray: 
    if (firstOrd(a.sons[0]) == 0) and
        (skipTypes(a.sons[0], {tyRange}).kind in {tyInt..tyInt64}) and
        (a.sons[1].kind == tyChar): 
      result = true
  
proc getProcHeader(sym: PSym): string = 
  result = sym.name.s & '('
  var n = sym.typ.n
  for i in countup(1, sonsLen(n) - 1): 
    var p = n.sons[i]
    if (p.kind != nkSym): InternalError("getProcHeader")
    add(result, p.sym.name.s)
    add(result, ": ")
    add(result, typeToString(p.sym.typ))
    if i != sonsLen(n) - 1: add(result, ", ")
  add(result, ')')
  if n.sons[0].typ != nil: result = result & ": " & typeToString(n.sons[0].typ)
  
proc elemType(t: PType): PType = 
  assert(t != nil)
  case t.kind
  of tyGenericInst, tyDistinct: result = elemType(lastSon(t))
  of tyArray, tyArrayConstr: result = t.sons[1]
  else: result = t.sons[0]
  assert(result != nil)

proc skipGeneric(t: PType): PType = 
  result = t
  while result.kind == tyGenericInst: result = lastSon(result)
  
proc skipRange(t: PType): PType = 
  result = t
  while result.kind == tyRange: result = base(result)
  
proc skipAbstract(t: PType): PType = 
  result = t
  while result.kind in {tyRange, tyGenericInst}: result = lastSon(result)
  
proc skipVar(t: PType): PType = 
  result = t
  while result.kind == tyVar: result = result.sons[0]
  
proc skipVarGeneric(t: PType): PType = 
  result = t
  while result.kind in {tyGenericInst, tyVar}: result = lastSon(result)
  
proc skipPtrsGeneric(t: PType): PType = 
  result = t
  while result.kind in {tyGenericInst, tyVar, tyPtr, tyRef}: 
    result = lastSon(result)
  
proc skipVarGenericRange(t: PType): PType = 
  result = t
  while result.kind in {tyGenericInst, tyVar, tyRange}: result = lastSon(result)
  
proc skipGenericRange(t: PType): PType = 
  result = t
  while result.kind in {tyGenericInst, tyVar, tyRange}: result = lastSon(result)
  
proc skipTypes(t: PType, kinds: TTypeKinds): PType = 
  result = t
  while result.kind in kinds: result = lastSon(result)
  
proc isOrdinalType(t: PType): bool = 
  assert(t != nil)
  result = (t.Kind in {tyChar, tyInt..tyInt64, tyBool, tyEnum}) or
      (t.Kind in {tyRange, tyOrdinal}) and isOrdinalType(t.sons[0])

proc enumHasWholes(t: PType): bool = 
  var b = t
  while b.kind == tyRange: b = b.sons[0]
  result = (b.Kind == tyEnum) and (tfEnumHasWholes in b.flags)

proc iterOverTypeAux(marker: var TIntSet, t: PType, iter: TTypeIter, 
                     closure: PObject): bool
proc iterOverNode(marker: var TIntSet, n: PNode, iter: TTypeIter, 
                  closure: PObject): bool = 
  result = false
  if n != nil: 
    case n.kind
    of nkNone..nkNilLit: 
      # a leaf
      result = iterOverTypeAux(marker, n.typ, iter, closure)
    else: 
      for i in countup(0, sonsLen(n) - 1): 
        result = iterOverNode(marker, n.sons[i], iter, closure)
        if result: return 
  
proc iterOverTypeAux(marker: var TIntSet, t: PType, iter: TTypeIter, 
                     closure: PObject): bool = 
  result = false
  if t == nil: return 
  result = iter(t, closure)
  if result: return 
  if not IntSetContainsOrIncl(marker, t.id): 
    case t.kind
    of tyGenericInst, tyGenericBody: 
      result = iterOverTypeAux(marker, lastSon(t), iter, closure)
    else: 
      for i in countup(0, sonsLen(t) - 1): 
        result = iterOverTypeAux(marker, t.sons[i], iter, closure)
        if result: return 
      if t.n != nil: result = iterOverNode(marker, t.n, iter, closure)
  
proc IterOverType(t: PType, iter: TTypeIter, closure: PObject): bool = 
  var marker: TIntSet
  IntSetInit(marker)
  result = iterOverTypeAux(marker, t, iter, closure)

proc searchTypeForAux(t: PType, predicate: TTypePredicate, 
                      marker: var TIntSet): bool

proc searchTypeNodeForAux(n: PNode, p: TTypePredicate, 
                          marker: var TIntSet): bool = 
  result = false
  case n.kind
  of nkRecList: 
    for i in countup(0, sonsLen(n) - 1): 
      result = searchTypeNodeForAux(n.sons[i], p, marker)
      if result: return 
  of nkRecCase: 
    assert(n.sons[0].kind == nkSym)
    result = searchTypeNodeForAux(n.sons[0], p, marker)
    if result: return 
    for i in countup(1, sonsLen(n) - 1): 
      case n.sons[i].kind
      of nkOfBranch, nkElse: 
        result = searchTypeNodeForAux(lastSon(n.sons[i]), p, marker)
        if result: return 
      else: internalError("searchTypeNodeForAux(record case branch)")
  of nkSym: 
    result = searchTypeForAux(n.sym.typ, p, marker)
  else: internalError(n.info, "searchTypeNodeForAux()")
  
proc searchTypeForAux(t: PType, predicate: TTypePredicate, marker: var TIntSet): bool = 
  # iterates over VALUE types!
  result = false
  if t == nil: return 
  if IntSetContainsOrIncl(marker, t.id): return 
  result = Predicate(t)
  if result: return 
  case t.kind
  of tyObject: 
    result = searchTypeForAux(t.sons[0], predicate, marker)
    if not result: result = searchTypeNodeForAux(t.n, predicate, marker)
  of tyGenericInst, tyDistinct: 
    result = searchTypeForAux(lastSon(t), predicate, marker)
  of tyArray, tyArrayConstr, tySet, tyTuple: 
    for i in countup(0, sonsLen(t) - 1): 
      result = searchTypeForAux(t.sons[i], predicate, marker)
      if result: return 
  else: 
    nil

proc searchTypeFor(t: PType, predicate: TTypePredicate): bool = 
  var marker: TIntSet
  IntSetInit(marker)
  result = searchTypeForAux(t, predicate, marker)

proc isObjectPredicate(t: PType): bool = 
  result = t.kind == tyObject

proc containsObject(t: PType): bool = 
  result = searchTypeFor(t, isObjectPredicate)

proc isObjectWithTypeFieldPredicate(t: PType): bool = 
  result = (t.kind == tyObject) and (t.sons[0] == nil) and
      not ((t.sym != nil) and (sfPure in t.sym.flags)) and
      not (tfFinal in t.flags)

proc analyseObjectWithTypeFieldAux(t: PType, marker: var TIntSet): TTypeFieldResult = 
  var res: TTypeFieldResult
  result = frNone
  if t == nil: return 
  case t.kind
  of tyObject: 
    if (t.n != nil): 
      if searchTypeNodeForAux(t.n, isObjectWithTypeFieldPredicate, marker): 
        return frEmbedded
    for i in countup(0, sonsLen(t) - 1): 
      res = analyseObjectWithTypeFieldAux(t.sons[i], marker)
      if res == frEmbedded: 
        return frEmbedded
      if res == frHeader: result = frHeader
    if result == frNone: 
      if isObjectWithTypeFieldPredicate(t): result = frHeader
  of tyGenericInst, tyDistinct: 
    result = analyseObjectWithTypeFieldAux(lastSon(t), marker)
  of tyArray, tyArrayConstr, tyTuple: 
    for i in countup(0, sonsLen(t) - 1): 
      res = analyseObjectWithTypeFieldAux(t.sons[i], marker)
      if res != frNone: 
        return frEmbedded
  else: 
    nil

proc analyseObjectWithTypeField(t: PType): TTypeFieldResult = 
  var marker: TIntSet
  IntSetInit(marker)
  result = analyseObjectWithTypeFieldAux(t, marker)

proc isGBCRef(t: PType): bool = 
  result = t.kind in {tyRef, tySequence, tyString}

proc containsGarbageCollectedRef(typ: PType): bool = 
  # returns true if typ contains a reference, sequence or string (all the things
  # that are garbage-collected)
  result = searchTypeFor(typ, isGBCRef)

proc isHiddenPointer(t: PType): bool = 
  result = t.kind in {tyString, tySequence}

proc containsHiddenPointer(typ: PType): bool = 
  # returns true if typ contains a string, table or sequence (all the things
  # that need to be copied deeply)
  result = searchTypeFor(typ, isHiddenPointer)

proc canFormAcycleAux(marker: var TIntSet, typ: PType, startId: int): bool
proc canFormAcycleNode(marker: var TIntSet, n: PNode, startId: int): bool = 
  result = false
  if n != nil: 
    result = canFormAcycleAux(marker, n.typ, startId)
    if not result: 
      case n.kind
      of nkNone..nkNilLit: 
        nil
      else: 
        for i in countup(0, sonsLen(n) - 1): 
          result = canFormAcycleNode(marker, n.sons[i], startId)
          if result: return 
  
proc canFormAcycleAux(marker: var TIntSet, typ: PType, startId: int): bool = 
  var t: PType
  result = false
  if typ == nil: return 
  if tfAcyclic in typ.flags: return 
  t = skipTypes(typ, abstractInst)
  if tfAcyclic in t.flags: return 
  case t.kind
  of tyTuple, tyObject, tyRef, tySequence, tyArray, tyArrayConstr, tyOpenArray: 
    if not IntSetContainsOrIncl(marker, t.id): 
      for i in countup(0, sonsLen(t) - 1): 
        result = canFormAcycleAux(marker, t.sons[i], startId)
        if result: return 
      if t.n != nil: result = canFormAcycleNode(marker, t.n, startId)
    else: 
      result = t.id == startId
  else: 
    nil

proc canFormAcycle(typ: PType): bool = 
  var marker: TIntSet
  IntSetInit(marker)
  result = canFormAcycleAux(marker, typ, typ.id)

proc mutateTypeAux(marker: var TIntSet, t: PType, iter: TTypeMutator, 
                   closure: PObject): PType
proc mutateNode(marker: var TIntSet, n: PNode, iter: TTypeMutator, 
                closure: PObject): PNode = 
  result = nil
  if n != nil: 
    result = copyNode(n)
    result.typ = mutateTypeAux(marker, n.typ, iter, closure)
    case n.kind
    of nkNone..nkNilLit: 
      # a leaf
    else: 
      for i in countup(0, sonsLen(n) - 1): 
        addSon(result, mutateNode(marker, n.sons[i], iter, closure))
  
proc mutateTypeAux(marker: var TIntSet, t: PType, iter: TTypeMutator, 
                   closure: PObject): PType = 
  result = nil
  if t == nil: return 
  result = iter(t, closure)
  if not IntSetContainsOrIncl(marker, t.id): 
    for i in countup(0, sonsLen(t) - 1): 
      result.sons[i] = mutateTypeAux(marker, result.sons[i], iter, closure)
      if (result.sons[i] == nil) and (result.kind == tyGenericInst): 
        assert(false)
    if t.n != nil: result.n = mutateNode(marker, t.n, iter, closure)
  assert(result != nil)

proc mutateType(t: PType, iter: TTypeMutator, closure: PObject): PType = 
  var marker: TIntSet
  IntSetInit(marker)
  result = mutateTypeAux(marker, t, iter, closure)

proc rangeToStr(n: PNode): string = 
  assert(n.kind == nkRange)
  result = ValueToString(n.sons[0]) & ".." & ValueToString(n.sons[1])

proc TypeToString(typ: PType, prefer: TPreferedDesc = preferName): string = 
  const 
    typeToStr: array[TTypeKind, string] = ["None", "bool", "Char", "empty", 
      "Array Constructor [$1]", "nil", "expr", "stmt", "typeDesc", 
      "GenericInvokation", "GenericBody", "GenericInst", "GenericParam", 
      "distinct $1", "enum", "ordinal[$1]", "array[$1, $2]", "object", "tuple", 
      "set[$1]", "range[$1]", "ptr ", "ref ", "var ", "seq[$1]", "proc", 
      "pointer", "OpenArray[$1]", "string", "CString", "Forward", "int", "int8", 
      "int16", "int32", "int64", "float", "float32", "float64", "float128"]
  var t = typ
  result = ""
  if t == nil: return 
  if (prefer == preferName) and (t.sym != nil): 
    return t.sym.Name.s
  case t.Kind
  of tyGenericInst: 
    result = typeToString(lastSon(t), prefer)
  of tyArray: 
    if t.sons[0].kind == tyRange: 
      result = "array[" & rangeToStr(t.sons[0].n) & ", " &
          typeToString(t.sons[1]) & ']'
    else: 
      result = "array[" & typeToString(t.sons[0]) & ", " &
          typeToString(t.sons[1]) & ']'
  of tyGenericInvokation, tyGenericBody: 
    result = typeToString(t.sons[0]) & '['
    for i in countup(1, sonsLen(t) - 1): 
      if i > 1: add(result, ", ")
      add(result, typeToString(t.sons[i]))
    add(result, ']')
  of tyArrayConstr: 
    result = "Array constructor[" & rangeToStr(t.sons[0].n) & ", " &
        typeToString(t.sons[1]) & ']'
  of tySequence: 
    result = "seq[" & typeToString(t.sons[0]) & ']'
  of tyOrdinal: 
    result = "ordinal[" & typeToString(t.sons[0]) & ']'
  of tySet: 
    result = "set[" & typeToString(t.sons[0]) & ']'
  of tyOpenArray: 
    result = "openarray[" & typeToString(t.sons[0]) & ']'
  of tyDistinct: 
    result = "distinct " & typeToString(t.sons[0], preferName)
  of tyTuple: 
    # we iterate over t.sons here, because t.n may be nil
    result = "tuple["
    if t.n != nil: 
      assert(sonsLen(t.n) == sonsLen(t))
      for i in countup(0, sonsLen(t.n) - 1): 
        assert(t.n.sons[i].kind == nkSym)
        add(result, t.n.sons[i].sym.name.s & ": " & typeToString(t.sons[i]))
        if i < sonsLen(t.n) - 1: add(result, ", ")
    else: 
      for i in countup(0, sonsLen(t) - 1): 
        add(result, typeToString(t.sons[i]))
        if i < sonsLen(t) - 1: add(result, ", ")
    add(result, ']')
  of tyPtr, tyRef, tyVar: 
    result = typeToStr[t.kind] & typeToString(t.sons[0])
  of tyRange: 
    result = "range " & rangeToStr(t.n)
  of tyProc: 
    result = "proc ("
    for i in countup(1, sonsLen(t) - 1): 
      add(result, typeToString(t.sons[i]))
      if i < sonsLen(t) - 1: add(result, ", ")
    add(result, ')')
    if t.sons[0] != nil: add(result, ": " & TypeToString(t.sons[0]))
    var prag: string
    if t.callConv != ccDefault: prag = CallingConvToStr[t.callConv]
    else: prag = ""
    if tfNoSideEffect in t.flags: 
      addSep(prag)
      add(prag, "noSideEffect")
    if len(prag) != 0: add(result, "{." & prag & ".}")
  else: 
    result = typeToStr[t.kind]

proc resultType(t: PType): PType = 
  assert(t.kind == tyProc)
  result = t.sons[0]          # nil is allowed
  
proc base(t: PType): PType = 
  result = t.sons[0]

proc firstOrd(t: PType): biggestInt = 
  case t.kind
  of tyBool, tyChar, tySequence, tyOpenArray, tyString: 
    result = 0
  of tySet, tyVar: 
    result = firstOrd(t.sons[0])
  of tyArray, tyArrayConstr: 
    result = firstOrd(t.sons[0])
  of tyRange: 
    assert(t.n != nil)        # range directly given:
    assert(t.n.kind == nkRange)
    result = getOrdValue(t.n.sons[0])
  of tyInt: 
    if platform.intSize == 4: result = - (2147483646) - 2
    else: result = 0x8000000000000000'i64
  of tyInt8: 
    result = - 128
  of tyInt16: 
    result = - 32768
  of tyInt32: 
    result = - 2147483646 - 2
  of tyInt64: 
    result = 0x8000000000000000'i64
  of tyEnum: 
    # if basetype <> nil then return firstOrd of basetype
    if (sonsLen(t) > 0) and (t.sons[0] != nil): 
      result = firstOrd(t.sons[0])
    else: 
      assert(t.n.sons[0].kind == nkSym)
      result = t.n.sons[0].sym.position
  of tyGenericInst, tyDistinct: 
    result = firstOrd(lastSon(t))
  else: 
    InternalError("invalid kind for first(" & $t.kind & ')')
    result = 0

proc lastOrd(t: PType): biggestInt = 
  case t.kind
  of tyBool: 
    result = 1
  of tyChar: 
    result = 255
  of tySet, tyVar: 
    result = lastOrd(t.sons[0])
  of tyArray, tyArrayConstr: 
    result = lastOrd(t.sons[0])
  of tyRange: 
    assert(t.n != nil)        # range directly given:
    assert(t.n.kind == nkRange)
    result = getOrdValue(t.n.sons[1])
  of tyInt: 
    if platform.intSize == 4: result = 0x7FFFFFFF
    else: result = 0x7FFFFFFFFFFFFFFF'i64
  of tyInt8: 
    result = 0x0000007F
  of tyInt16: 
    result = 0x00007FFF
  of tyInt32: 
    result = 0x7FFFFFFF
  of tyInt64: 
    result = 0x7FFFFFFFFFFFFFFF'i64
  of tyEnum: 
    assert(t.n.sons[sonsLen(t.n) - 1].kind == nkSym)
    result = t.n.sons[sonsLen(t.n) - 1].sym.position
  of tyGenericInst, tyDistinct: 
    result = firstOrd(lastSon(t))
  else: 
    InternalError("invalid kind for last(" & $t.kind & ')')
    result = 0

proc lengthOrd(t: PType): biggestInt = 
  case t.kind
  of tyInt64, tyInt32, tyInt: result = lastOrd(t)
  of tyDistinct: result = lengthOrd(t.sons[0])
  else: result = lastOrd(t) - firstOrd(t) + 1
  
proc equalParam(a, b: PSym): TParamsEquality = 
  if SameTypeOrNil(a.typ, b.typ): 
    if (a.ast == b.ast): 
      result = paramsEqual
    elif (a.ast != nil) and (b.ast != nil): 
      if ExprStructuralEquivalent(a.ast, b.ast): result = paramsEqual
      else: result = paramsIncompatible
    elif (a.ast != nil): 
      result = paramsEqual
    elif (b.ast != nil): 
      result = paramsIncompatible
  else: 
    result = paramsNotEqual
  
proc equalParams(a, b: PNode): TParamsEquality = 
  var 
    length: int
    m, n: PSym
  result = paramsEqual
  length = sonsLen(a)
  if length != sonsLen(b): 
    result = paramsNotEqual
  else: 
    for i in countup(1, length - 1): 
      m = a.sons[i].sym
      n = b.sons[i].sym
      assert((m.kind == skParam) and (n.kind == skParam))
      case equalParam(m, n)
      of paramsNotEqual: 
        return paramsNotEqual
      of paramsEqual: 
        nil
      of paramsIncompatible: 
        result = paramsIncompatible
      if (m.name.id != n.name.id): 
        # BUGFIX
        return paramsNotEqual # paramsIncompatible;
      # continue traversal! If not equal, we can return immediately; else
      # it stays incompatible
    if not SameTypeOrNil(a.sons[0].typ, b.sons[0].typ): 
      if (a.sons[0].typ == nil) or (b.sons[0].typ == nil): 
        result = paramsNotEqual # one proc has a result, the other not is OK
      else: 
        result = paramsIncompatible # overloading by different
                                    # result types does not work
  
proc SameTypeOrNil(a, b: PType): bool = 
  if a == b: 
    result = true
  else: 
    if (a == nil) or (b == nil): result = false
    else: result = SameType(a, b)
  
proc SameLiteral(x, y: PNode): bool = 
  result = false
  if x.kind == y.kind: 
    case x.kind
    of nkCharLit..nkInt64Lit: result = x.intVal == y.intVal
    of nkFloatLit..nkFloat64Lit: result = x.floatVal == y.floatVal
    of nkNilLit: result = true
    else: assert(false)
  
proc SameRanges(a, b: PNode): bool = 
  result = SameLiteral(a.sons[0], b.sons[0]) and
      SameLiteral(a.sons[1], b.sons[1])

proc sameTuple(a, b: PType, DistinctOf: bool): bool = 
  # two tuples are equivalent iff the names, types and positions are the same;
  # however, both types may not have any field names (t.n may be nil) which
  # complicates the matter a bit.
  var x, y: PSym
  if sonsLen(a) == sonsLen(b): 
    result = true
    for i in countup(0, sonsLen(a) - 1): 
      if DistinctOf: result = equalOrDistinctOf(a.sons[i], b.sons[i])
      else: result = SameType(a.sons[i], b.sons[i])
      if not result: return 
    if (a.n != nil) and (b.n != nil): 
      for i in countup(0, sonsLen(a.n) - 1): 
        # check field names: 
        if a.n.sons[i].kind != nkSym: InternalError(a.n.info, "sameTuple")
        if b.n.sons[i].kind != nkSym: InternalError(b.n.info, "sameTuple")
        x = a.n.sons[i].sym
        y = b.n.sons[i].sym
        result = x.name.id == y.name.id
        if not result: break 
  else: 
    result = false
  
proc SameType(x, y: PType): bool = 
  if x == y: 
    return true
  var a = skipTypes(x, {tyGenericInst})
  var b = skipTypes(y, {tyGenericInst})
  assert(a != nil)
  assert(b != nil)
  if a.kind != b.kind: 
    return false
  case a.Kind
  of tyEmpty, tyChar, tyBool, tyNil, tyPointer, tyString, tyCString, 
     tyInt..tyFloat128, tyExpr, tyStmt, tyTypeDesc: 
    result = true
  of tyEnum, tyForward, tyObject, tyDistinct: 
    result = (a.id == b.id)
  of tyTuple: 
    result = sameTuple(a, b, false)
  of tyGenericInst: 
    result = sameType(lastSon(a), lastSon(b))
  of tyGenericParam, tyGenericInvokation, tyGenericBody, tySequence, tyOrdinal, 
     tyOpenArray, tySet, tyRef, tyPtr, tyVar, tyArrayConstr, tyArray, tyProc: 
    if sonsLen(a) == sonsLen(b): 
      result = true
      for i in countup(0, sonsLen(a) - 1): 
        result = SameTypeOrNil(a.sons[i], b.sons[i]) # BUGFIX
        if not result: return 
      if result and (a.kind == tyProc): 
        result = a.callConv == b.callConv # BUGFIX
    else: 
      result = false
  of tyRange: 
    result = SameTypeOrNil(a.sons[0], b.sons[0]) and
        SameValue(a.n.sons[0], b.n.sons[0]) and
        SameValue(a.n.sons[1], b.n.sons[1])
  of tyNone: 
    result = false
  
proc equalOrDistinctOf(x, y: PType): bool = 
  if x == y: 
    return true
  if (x == nil) or (y == nil): 
    return false
  var a = skipTypes(x, {tyGenericInst})
  var b = skipTypes(y, {tyGenericInst})
  assert(a != nil)
  assert(b != nil)
  if a.kind != b.kind: 
    if a.kind == tyDistinct: a = a.sons[0]
    if a.kind != b.kind: 
      return false
  case a.Kind
  of tyEmpty, tyChar, tyBool, tyNil, tyPointer, tyString, tyCString, 
     tyInt..tyFloat128, tyExpr, tyStmt, tyTypeDesc: 
    result = true
  of tyEnum, tyForward, tyObject, tyDistinct: 
    result = (a.id == b.id)
  of tyTuple: 
    result = sameTuple(a, b, true)
  of tyGenericInst: 
    result = equalOrDistinctOf(lastSon(a), lastSon(b))
  of tyGenericParam, tyGenericInvokation, tyGenericBody, tySequence, tyOrdinal, 
     tyOpenArray, tySet, tyRef, tyPtr, tyVar, tyArrayConstr, tyArray, tyProc: 
    if sonsLen(a) == sonsLen(b): 
      result = true
      for i in countup(0, sonsLen(a) - 1): 
        result = equalOrDistinctOf(a.sons[i], b.sons[i])
        if not result: return 
      if result and (a.kind == tyProc): result = a.callConv == b.callConv
    else: 
      result = false
  of tyRange: 
    result = equalOrDistinctOf(a.sons[0], b.sons[0]) and
        SameValue(a.n.sons[0], b.n.sons[0]) and
        SameValue(a.n.sons[1], b.n.sons[1])
  of tyNone: 
    result = false
  
proc typeAllowedAux(marker: var TIntSet, typ: PType, kind: TSymKind): bool
proc typeAllowedNode(marker: var TIntSet, n: PNode, kind: TSymKind): bool = 
  result = true
  if n != nil: 
    result = typeAllowedAux(marker, n.typ, kind)
    if not result: debug(n.typ)
    if result: 
      case n.kind
      of nkNone..nkNilLit: 
        nil
      else: 
        for i in countup(0, sonsLen(n) - 1): 
          result = typeAllowedNode(marker, n.sons[i], kind)
          if not result: return 
  
proc typeAllowedAux(marker: var TIntSet, typ: PType, kind: TSymKind): bool = 
  var t, t2: PType
  assert(kind in {skVar, skConst, skParam})
  result = true
  if typ == nil: 
    return # if we have already checked the type, return true, because we stop the
           # evaluation if something is wrong:
  if IntSetContainsOrIncl(marker, typ.id): return 
  t = skipTypes(typ, abstractInst)
  case t.kind
  of tyVar: 
    t2 = skipTypes(t.sons[0], abstractInst)
    case t2.kind
    of tyVar: 
      result = false          # ``var var`` is always an invalid type:
    of tyOpenArray: 
      result = (kind == skParam) and typeAllowedAux(marker, t2, kind)
    else: result = (kind != skConst) and typeAllowedAux(marker, t2, kind)
  of tyProc: 
    for i in countup(1, sonsLen(t) - 1): 
      result = typeAllowedAux(marker, t.sons[i], skParam)
      if not result: return 
    if t.sons[0] != nil: result = typeAllowedAux(marker, t.sons[0], skVar)
  of tyExpr, tyStmt, tyTypeDesc: 
    result = true
  of tyGenericBody, tyGenericParam, tyForward, tyNone, tyGenericInvokation: 
    result = false            #InternalError('shit found');
  of tyEmpty, tyNil: 
    result = kind == skConst
  of tyString, tyBool, tyChar, tyEnum, tyInt..tyFloat128, tyCString, tyPointer: 
    result = true
  of tyOrdinal: 
    result = kind == skParam
  of tyGenericInst, tyDistinct: 
    result = typeAllowedAux(marker, lastSon(t), kind)
  of tyRange: 
    result = skipTypes(t.sons[0], abstractInst).kind in
        {tyChar, tyEnum, tyInt..tyFloat128}
  of tyOpenArray: 
    result = (kind == skParam) and typeAllowedAux(marker, t.sons[0], skVar)
  of tySequence: 
    result = (kind != skConst) and typeAllowedAux(marker, t.sons[0], skVar) or
        (t.sons[0].kind == tyEmpty)
  of tyArray: 
    result = typeAllowedAux(marker, t.sons[1], skVar)
  of tyPtr, tyRef: 
    result = typeAllowedAux(marker, t.sons[0], skVar)
  of tyArrayConstr, tyTuple, tySet: 
    for i in countup(0, sonsLen(t) - 1): 
      result = typeAllowedAux(marker, t.sons[i], kind)
      if not result: return 
  of tyObject: 
    for i in countup(0, sonsLen(t) - 1): 
      result = typeAllowedAux(marker, t.sons[i], skVar)
      if not result: return 
    if t.n != nil: result = typeAllowedNode(marker, t.n, skVar)
  
proc typeAllowed(t: PType, kind: TSymKind): bool = 
  var marker: TIntSet
  IntSetInit(marker)
  result = typeAllowedAux(marker, t, kind)

proc align(address, alignment: biggestInt): biggestInt = 
  result = (address + (alignment - 1)) and not (alignment - 1)

proc computeSizeAux(typ: PType, a: var biggestInt): biggestInt
proc computeRecSizeAux(n: PNode, a, currOffset: var biggestInt): biggestInt = 
  var maxAlign, maxSize, b, res: biggestInt
  case n.kind
  of nkRecCase: 
    assert(n.sons[0].kind == nkSym)
    result = computeRecSizeAux(n.sons[0], a, currOffset)
    maxSize = 0
    maxAlign = 1
    for i in countup(1, sonsLen(n) - 1): 
      case n.sons[i].kind
      of nkOfBranch, nkElse: 
        res = computeRecSizeAux(lastSon(n.sons[i]), b, currOffset)
        if res < 0: 
          return res
        maxSize = max(maxSize, res)
        maxAlign = max(maxAlign, b)
      else: internalError("computeRecSizeAux(record case branch)")
    currOffset = align(currOffset, maxAlign) + maxSize
    result = align(result, maxAlign) + maxSize
    a = maxAlign
  of nkRecList: 
    result = 0
    maxAlign = 1
    for i in countup(0, sonsLen(n) - 1): 
      res = computeRecSizeAux(n.sons[i], b, currOffset)
      if res < 0: 
        return res
      currOffset = align(currOffset, b) + res
      result = align(result, b) + res
      if b > maxAlign: maxAlign = b
    a = maxAlign
  of nkSym: 
    result = computeSizeAux(n.sym.typ, a)
    n.sym.offset = int(currOffset)
  else: 
    InternalError("computeRecSizeAux()")
    a = 1
    result = - 1

proc computeSizeAux(typ: PType, a: var biggestInt): biggestInt = 
  var res, maxAlign, length, currOffset: biggestInt
  if typ.size == - 2: 
    # we are already computing the size of the type
    # --> illegal recursion in type
    return - 2
  if typ.size >= 0: 
    # size already computed
    result = typ.size
    a = typ.align
    return 
  typ.size = - 2              # mark as being computed
  case typ.kind
  of tyInt: 
    result = IntSize
    a = result
  of tyInt8, tyBool, tyChar: 
    result = 1
    a = result
  of tyInt16: 
    result = 2
    a = result
  of tyInt32, tyFloat32: 
    result = 4
    a = result
  of tyInt64, tyFloat64: 
    result = 8
    a = result
  of tyFloat: 
    result = floatSize
    a = result
  of tyProc: 
    if typ.callConv == ccClosure: result = 2 * ptrSize
    else: result = ptrSize
    a = ptrSize
  of tyNil, tyCString, tyString, tySequence, tyPtr, tyRef, tyOpenArray: 
    result = ptrSize
    a = result
  of tyArray, tyArrayConstr: 
    result = lengthOrd(typ.sons[0]) * computeSizeAux(typ.sons[1], a)
  of tyEnum: 
    if firstOrd(typ) < 0: 
      result = 4              # use signed int32
    else: 
      length = lastOrd(typ)   # BUGFIX: use lastOrd!
      if length + 1 < `shl`(1, 8): result = 1
      elif length + 1 < `shl`(1, 16): result = 2
      elif length + 1 < `shl`(biggestInt(1), 32): result = 4
      else: result = 8
    a = result
  of tySet: 
    length = lengthOrd(typ.sons[0])
    if length <= 8: 
      result = 1
    elif length <= 16: 
      result = 2
    elif length <= 32: 
      result = 4
    elif length <= 64: 
      result = 8
    elif align(length, 8) mod 8 == 0: 
      result = align(length, 8) div 8
    else: 
      result = align(length, 8) div 8 + 1 # BUGFIX!
    a = result
  of tyRange: 
    result = computeSizeAux(typ.sons[0], a)
  of tyTuple: 
    result = 0
    maxAlign = 1
    for i in countup(0, sonsLen(typ) - 1): 
      res = computeSizeAux(typ.sons[i], a)
      if res < 0: 
        return res
      maxAlign = max(maxAlign, a)
      result = align(result, a) + res
    result = align(result, maxAlign)
    a = maxAlign
  of tyObject: 
    if typ.sons[0] != nil: 
      result = computeSizeAux(typ.sons[0], a)
      if result < 0: return 
      maxAlign = a
    elif isObjectWithTypeFieldPredicate(typ): 
      result = intSize
      maxAlign = result
    else: 
      result = 0
      maxAlign = 1
    currOffset = result
    result = computeRecSizeAux(typ.n, a, currOffset)
    if result < 0: return 
    if a < maxAlign: a = maxAlign
    result = align(result, a)
  of tyGenericInst, tyDistinct, tyGenericBody: 
    result = computeSizeAux(lastSon(typ), a)
  else: 
    #internalError('computeSizeAux()');
    result = - 1
  typ.size = result
  typ.align = int(a)

proc computeSize(typ: PType): biggestInt = 
  var a: biggestInt = 1
  result = computeSizeAux(typ, a)

proc getSize(typ: PType): biggestInt = 
  result = computeSize(typ)
  if result < 0: InternalError("getSize(" & $typ.kind & ')')
  
