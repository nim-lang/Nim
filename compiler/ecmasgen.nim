#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This is the EMCAScript (also known as JavaScript) code generator.
# **Invariant: each expression occurs only once in the generated
# code!**

import 
  ast, astalgo, strutils, hashes, trees, platform, magicsys, extccomp,
  options, nversion, nimsets, msgs, crc, bitsets, idents, lists, types, os,
  times, ropes, math, passes, ccgutils, wordrecg, renderer, rodread, rodutils,
  intsets, cgmeth

proc ecmasgenPass*(): TPass
# implementation

type 
  TEcmasGen = object of TPassContext
    filename: string
    module: PSym

  BModule = ref TEcmasGen
  TEcmasTypeKind = enum       # necessary JS "types"
    etyNone,                  # no type
    etyNull,                  # null type
    etyProc,                  # proc type
    etyBool,                  # bool type
    etyInt,                   # Ecmascript's int
    etyFloat,                 # Ecmascript's float
    etyString,                # Ecmascript's string
    etyObject,                # Ecmascript's reference to an object
    etyBaseIndex              # base + index needed
  TCompRes{.final.} = object 
    kind: TEcmasTypeKind
    com: PRope               # computation part
                             # address if this is a (address, index)-tuple
    res: PRope               # result part; index if this is an
                             # (address, index)-tuple
  
  TBlock{.final.} = object 
    id: int                  # the ID of the label; positive means that it
                             # has been used (i.e. the label should be emitted)
    nestedTryStmts: int      # how many try statements is it nested into
    isLoop: bool             # whether it's a 'block' or 'while'
  
  TGlobals{.final.} = object 
    typeInfo, code: PRope
    forwarded: seq[PSym]
    generatedSyms: TIntSet
    typeInfoGenerated: TIntSet

  PGlobals = ref TGlobals
  TProc{.final.} = object 
    procDef: PNode
    prc: PSym
    data: PRope
    options: TOptions
    module: BModule
    g: PGlobals
    BeforeRetNeeded: bool
    nestedTryStmts: int
    unique: int
    blocks: seq[TBlock]


proc newGlobals(): PGlobals = 
  new(result)
  result.forwarded = @[]
  result.generatedSyms = initIntSet()
  result.typeInfoGenerated = initIntSet()

proc initCompRes(r: var TCompRes) = 
  r.com = nil
  r.res = nil
  r.kind = etyNone

proc initProc(p: var TProc, globals: PGlobals, module: BModule, procDef: PNode, 
              options: TOptions) = 
  p.blocks = @[]
  p.options = options
  p.module = module
  p.procDef = procDef
  p.g = globals
  if procDef != nil: p.prc = procDef.sons[namePos].sym
  
const 
  MappedToObject = {tyObject, tyArray, tyArrayConstr, tyTuple, tyOpenArray, 
    tySet, tyVar, tyRef, tyPtr, tyBigNum}

proc mapType(typ: PType): TEcmasTypeKind = 
  var t = skipTypes(typ, abstractInst)
  case t.kind
  of tyVar, tyRef, tyPtr: 
    if skipTypes(t.sons[0], abstractInst).kind in mappedToObject: 
      result = etyObject
    else: 
      result = etyBaseIndex
  of tyPointer:
    # treat a tyPointer like a typed pointer to an array of bytes
    result = etyInt
  of tyRange, tyDistinct, tyOrdinal, tyConst, tyMutable, tyIter, tyVarargs,
     tyProxy: 
    result = mapType(t.sons[0])
  of tyInt..tyInt64, tyUInt..tyUInt64, tyEnum, tyChar: result = etyInt
  of tyBool: result = etyBool
  of tyFloat..tyFloat128: result = etyFloat
  of tySet: result = etyObject # map a set to a table
  of tyString, tySequence: result = etyInt # little hack to get right semantics
  of tyObject, tyArray, tyArrayConstr, tyTuple, tyOpenArray, tyBigNum: 
    result = etyObject
  of tyNil: result = etyNull
  of tyGenericInst, tyGenericParam, tyGenericBody, tyGenericInvokation, tyNone, 
     tyForward, tyEmpty, tyExpr, tyStmt, tyTypeDesc, tyTypeClass: 
    result = etyNone
  of tyProc: result = etyProc
  of tyCString: result = etyString
  
proc mangle(name: string): string = 
  result = ""
  for i in countup(0, len(name) - 1): 
    case name[i]
    of 'A'..'Z': 
      add(result, chr(ord(name[i]) - ord('A') + ord('a')))
    of '_': 
      nil
    of 'a'..'z', '0'..'9': 
      add(result, name[i])
    else: add(result, 'X' & toHex(ord(name[i]), 2))
  
proc mangleName(s: PSym): PRope = 
  result = s.loc.r
  if result == nil: 
    result = toRope(mangle(s.name.s))
    app(result, "_")
    app(result, toRope(s.id))
    s.loc.r = result

proc genTypeInfo(p: var TProc, typ: PType): PRope
proc genObjectFields(p: var TProc, typ: PType, n: PNode): PRope = 
  var 
    s, u: PRope
    length: int
    field: PSym
    b: PNode
  result = nil
  case n.kind
  of nkRecList: 
    length = sonsLen(n)
    if length == 1: 
      result = genObjectFields(p, typ, n.sons[0])
    else: 
      s = nil
      for i in countup(0, length - 1): 
        if i > 0: app(s, ", " & tnl)
        app(s, genObjectFields(p, typ, n.sons[i]))
      result = ropef("{kind: 2, len: $1, offset: 0, " &
          "typ: null, name: null, sons: [$2]}", [toRope(length), s])
  of nkSym: 
    field = n.sym
    s = genTypeInfo(p, field.typ)
    result = ropef("{kind: 1, offset: \"$1\", len: 0, " &
        "typ: $2, name: $3, sons: null}", 
                   [mangleName(field), s, makeCString(field.name.s)])
  of nkRecCase: 
    length = sonsLen(n)
    if (n.sons[0].kind != nkSym): InternalError(n.info, "genObjectFields")
    field = n.sons[0].sym
    s = genTypeInfo(p, field.typ)
    for i in countup(1, length - 1): 
      b = n.sons[i]           # branch
      u = nil
      case b.kind
      of nkOfBranch: 
        if sonsLen(b) < 2: 
          internalError(b.info, "genObjectFields; nkOfBranch broken")
        for j in countup(0, sonsLen(b) - 2): 
          if u != nil: app(u, ", ")
          if b.sons[j].kind == nkRange: 
            appf(u, "[$1, $2]", [toRope(getOrdValue(b.sons[j].sons[0])), 
                                 toRope(getOrdValue(b.sons[j].sons[1]))])
          else: 
            app(u, toRope(getOrdValue(b.sons[j])))
      of nkElse: 
        u = toRope(lengthOrd(field.typ))
      else: internalError(n.info, "genObjectFields(nkRecCase)")
      if result != nil: app(result, ", " & tnl)
      appf(result, "[SetConstr($1), $2]", 
           [u, genObjectFields(p, typ, lastSon(b))])
    result = ropef("{kind: 3, offset: \"$1\", len: $3, " &
        "typ: $2, name: $4, sons: [$5]}", [mangleName(field), s, 
        toRope(lengthOrd(field.typ)), makeCString(field.name.s), result])
  else: internalError(n.info, "genObjectFields")
  
proc genObjectInfo(p: var TProc, typ: PType, name: PRope) = 
  var s = ropef("var $1 = {size: 0, kind: $2, base: null, node: null, " &
                "finalizer: null};$n", [name, toRope(ord(typ.kind))])
  prepend(p.g.typeInfo, s)
  appf(p.g.typeInfo, "var NNI$1 = $2;$n", 
       [toRope(typ.id), genObjectFields(p, typ, typ.n)])
  appf(p.g.typeInfo, "$1.node = NNI$2;$n", [name, toRope(typ.id)])
  if (typ.kind == tyObject) and (typ.sons[0] != nil): 
    appf(p.g.typeInfo, "$1.base = $2;$n", 
         [name, genTypeInfo(p, typ.sons[0])])

proc genEnumInfo(p: var TProc, typ: PType, name: PRope) = 
  var 
    s, n: PRope
    length: int
    field: PSym
  length = sonsLen(typ.n)
  s = nil
  for i in countup(0, length - 1): 
    if (typ.n.sons[i].kind != nkSym): InternalError(typ.n.info, "genEnumInfo")
    field = typ.n.sons[i].sym
    if i > 0: app(s, ", " & tnl)
    appf(s, "{kind: 1, offset: $1, typ: $2, name: $3, len: 0, sons: null}", 
         [toRope(field.position), name, makeCString(field.name.s)])
  n = ropef("var NNI$1 = {kind: 2, offset: 0, typ: null, " &
      "name: null, len: $2, sons: [$3]};$n", [toRope(typ.id), toRope(length), s])
  s = ropef("var $1 = {size: 0, kind: $2, base: null, node: null, " &
      "finalizer: null};$n", [name, toRope(ord(typ.kind))])
  prepend(p.g.typeInfo, s)
  app(p.g.typeInfo, n)
  appf(p.g.typeInfo, "$1.node = NNI$2;$n", [name, toRope(typ.id)])
  if typ.sons[0] != nil: 
    appf(p.g.typeInfo, "$1.base = $2;$n", 
         [name, genTypeInfo(p, typ.sons[0])])

proc genTypeInfo(p: var TProc, typ: PType): PRope = 
  var t = typ
  if t.kind == tyGenericInst: t = lastSon(t)
  result = ropef("NTI$1", [toRope(t.id)])
  if ContainsOrIncl(p.g.TypeInfoGenerated, t.id): return 
  case t.kind
  of tyDistinct: 
    result = genTypeInfo(p, typ.sons[0])
  of tyPointer, tyProc, tyBool, tyChar, tyCString, tyString, tyInt..tyFloat128: 
    var s = ropef(
      "var $1 = {size: 0,kind: $2,base: null,node: null,finalizer: null};$n", 
              [result, toRope(ord(t.kind))])
    prepend(p.g.typeInfo, s)
  of tyVar, tyRef, tyPtr, tySequence, tyRange, tySet: 
    var s = ropef(
      "var $1 = {size: 0,kind: $2,base: null,node: null,finalizer: null};$n", 
              [result, toRope(ord(t.kind))])
    prepend(p.g.typeInfo, s)
    appf(p.g.typeInfo, "$1.base = $2;$n", 
         [result, genTypeInfo(p, typ.sons[0])])
  of tyArrayConstr, tyArray: 
    var s = ropef(
      "var $1 = {size: 0,kind: $2,base: null,node: null,finalizer: null};$n",
              [result, toRope(ord(t.kind))])
    prepend(p.g.typeInfo, s)
    appf(p.g.typeInfo, "$1.base = $2;$n", 
         [result, genTypeInfo(p, typ.sons[1])])
  of tyEnum: genEnumInfo(p, t, result)
  of tyObject, tyTuple: genObjectInfo(p, t, result)
  else: InternalError("genTypeInfo(" & $t.kind & ')')
  
proc gen(p: var TProc, n: PNode, r: var TCompRes)
proc genStmt(p: var TProc, n: PNode, r: var TCompRes)
proc genProc(oldProc: var TProc, prc: PSym, r: var TCompRes)
proc genConstant(p: var TProc, c: PSym, r: var TCompRes)

proc mergeExpr(a, b: PRope): PRope = 
  if (a != nil): 
    if b != nil: result = ropef("($1, $2)", [a, b])
    else: result = a
  else: 
    result = b
  
proc mergeExpr(r: TCompRes): PRope = 
  result = mergeExpr(r.com, r.res)

proc mergeStmt(r: TCompRes): PRope = 
  if r.res == nil: result = r.com
  elif r.com == nil: result = r.res
  else: result = ropef("$1$2", [r.com, r.res])
  
proc useMagic(p: var TProc, name: string) =
  if name.len == 0: return
  var s = magicsys.getCompilerProc(name)
  if s != nil:
    internalAssert s.kind in {skProc, skMethod, skConverter}
    if not p.g.generatedSyms.containsOrIncl(s.id):
      var r: TCompRes
      genProc(p, s, r)
      app(p.g.code, mergeStmt(r))
  else:
    # we used to exclude the system module from this check, but for DLL
    # generation support this sloppyness leads to hard to detect bugs, so
    # we're picky here for the system module too:
    if p.prc != nil: GlobalError(p.prc.info, errSystemNeeds, name)
    else: rawMessage(errSystemNeeds, name)

proc genAnd(p: var TProc, a, b: PNode, r: var TCompRes) = 
  var x, y: TCompRes
  gen(p, a, x)
  gen(p, b, y)
  r.res = ropef("($1 && $2)", [mergeExpr(x), mergeExpr(y)])

proc genOr(p: var TProc, a, b: PNode, r: var TCompRes) = 
  var x, y: TCompRes
  gen(p, a, x)
  gen(p, b, y)
  r.res = ropef("($1 || $2)", [mergeExpr(x), mergeExpr(y)])

type 
  TMagicFrmt = array[0..3, string]

const # magic checked op; magic unchecked op; checked op; unchecked op
  ops: array[mAddi..mStrToStr, TMagicFrmt] = [
    ["addInt", "", "addInt($1, $2)", "($1 + $2)"], # AddI
    ["subInt", "", "subInt($1, $2)", "($1 - $2)"], # SubI
    ["mulInt", "", "mulInt($1, $2)", "($1 * $2)"], # MulI
    ["divInt", "", "divInt($1, $2)", "Math.floor($1 / $2)"], # DivI
    ["modInt", "", "modInt($1, $2)", "Math.floor($1 % $2)"], # ModI
    ["addInt64", "", "addInt64($1, $2)", "($1 + $2)"], # AddI64
    ["subInt64", "", "subInt64($1, $2)", "($1 - $2)"], # SubI64
    ["mulInt64", "", "mulInt64($1, $2)", "($1 * $2)"], # MulI64
    ["divInt64", "", "divInt64($1, $2)", "Math.floor($1 / $2)"], # DivI64
    ["modInt64", "", "modInt64($1, $2)", "Math.floor($1 % $2)"], # ModI64
    ["", "", "($1 + $2)", "($1 + $2)"], # AddF64
    ["", "", "($1 - $2)", "($1 - $2)"], # SubF64
    ["", "", "($1 * $2)", "($1 * $2)"], # MulF64
    ["", "", "($1 / $2)", "($1 / $2)"], # DivF64
    ["", "", "($1 >>> $2)", "($1 >>> $2)"], # ShrI
    ["", "", "($1 << $2)", "($1 << $2)"], # ShlI
    ["", "", "($1 & $2)", "($1 & $2)"], # BitandI
    ["", "", "($1 | $2)", "($1 | $2)"], # BitorI
    ["", "", "($1 ^ $2)", "($1 ^ $2)"], # BitxorI
    ["nimMin", "nimMin", "nimMin($1, $2)", "nimMin($1, $2)"], # MinI
    ["nimMax", "nimMax", "nimMax($1, $2)", "nimMax($1, $2)"], # MaxI
    ["", "", "($1 >>> $2)", "($1 >>> $2)"], # ShrI64
    ["", "", "($1 << $2)", "($1 << $2)"], # ShlI64
    ["", "", "($1 & $2)", "($1 & $2)"], # BitandI64
    ["", "", "($1 | $2)", "($1 | $2)"], # BitorI64
    ["", "", "($1 ^ $2)", "($1 ^ $2)"], # BitxorI64
    ["nimMin", "nimMin", "nimMin($1, $2)", "nimMin($1, $2)"], # MinI64
    ["nimMax", "nimMax", "nimMax($1, $2)", "nimMax($1, $2)"], # MaxI64
    ["nimMin", "nimMin", "nimMin($1, $2)", "nimMin($1, $2)"], # MinF64
    ["nimMax", "nimMax", "nimMax($1, $2)", "nimMax($1, $2)"], # MaxF64
    ["AddU", "AddU", "AddU($1, $2)", "AddU($1, $2)"], # AddU
    ["SubU", "SubU", "SubU($1, $2)", "SubU($1, $2)"], # SubU
    ["MulU", "MulU", "MulU($1, $2)", "MulU($1, $2)"], # MulU
    ["DivU", "DivU", "DivU($1, $2)", "DivU($1, $2)"], # DivU
    ["ModU", "ModU", "ModU($1, $2)", "ModU($1, $2)"], # ModU
    ["AddU64", "AddU64", "AddU64($1, $2)", "AddU64($1, $2)"], # AddU64
    ["SubU64", "SubU64", "SubU64($1, $2)", "SubU64($1, $2)"], # SubU64
    ["MulU64", "MulU64", "MulU64($1, $2)", "MulU64($1, $2)"], # MulU64
    ["DivU64", "DivU64", "DivU64($1, $2)", "DivU64($1, $2)"], # DivU64
    ["ModU64", "ModU64", "ModU64($1, $2)", "ModU64($1, $2)"], # ModU64
    ["", "", "($1 == $2)", "($1 == $2)"], # EqI
    ["", "", "($1 <= $2)", "($1 <= $2)"], # LeI
    ["", "", "($1 < $2)", "($1 < $2)"], # LtI
    ["", "", "($1 == $2)", "($1 == $2)"], # EqI64
    ["", "", "($1 <= $2)", "($1 <= $2)"], # LeI64
    ["", "", "($1 < $2)", "($1 < $2)"], # LtI64
    ["", "", "($1 == $2)", "($1 == $2)"], # EqF64
    ["", "", "($1 <= $2)", "($1 <= $2)"], # LeF64
    ["", "", "($1 < $2)", "($1 < $2)"], # LtF64
    ["LeU", "LeU", "LeU($1, $2)", "LeU($1, $2)"], # LeU
    ["LtU", "LtU", "LtU($1, $2)", "LtU($1, $2)"], # LtU
    ["LeU64", "LeU64", "LeU64($1, $2)", "LeU64($1, $2)"], # LeU64
    ["LtU64", "LtU64", "LtU64($1, $2)", "LtU64($1, $2)"], # LtU64
    ["", "", "($1 == $2)", "($1 == $2)"], # EqEnum
    ["", "", "($1 <= $2)", "($1 <= $2)"], # LeEnum
    ["", "", "($1 < $2)", "($1 < $2)"], # LtEnum
    ["", "", "($1 == $2)", "($1 == $2)"], # EqCh
    ["", "", "($1 <= $2)", "($1 <= $2)"], # LeCh
    ["", "", "($1 < $2)", "($1 < $2)"], # LtCh
    ["", "", "($1 == $2)", "($1 == $2)"], # EqB
    ["", "", "($1 <= $2)", "($1 <= $2)"], # LeB
    ["", "", "($1 < $2)", "($1 < $2)"], # LtB
    ["", "", "($1 == $2)", "($1 == $2)"], # EqRef
    ["", "", "($1 == $2)", "($1 == $2)"], # EqProc
    ["", "", "($1 == $2)", "($1 == $2)"], # EqUntracedRef
    ["", "", "($1 <= $2)", "($1 <= $2)"], # LePtr
    ["", "", "($1 < $2)", "($1 < $2)"], # LtPtr
    ["", "", "($1 == $2)", "($1 == $2)"], # EqCString
    ["", "", "($1 != $2)", "($1 != $2)"], # Xor
    ["NegInt", "", "NegInt($1)", "-($1)"], # UnaryMinusI
    ["NegInt64", "", "NegInt64($1)", "-($1)"], # UnaryMinusI64
    ["AbsInt", "", "AbsInt($1)", "Math.abs($1)"], # AbsI
    ["AbsInt64", "", "AbsInt64($1)", "Math.abs($1)"], # AbsI64
    ["", "", "!($1)", "!($1)"], # Not
    ["", "", "+($1)", "+($1)"], # UnaryPlusI
    ["", "", "~($1)", "~($1)"], # BitnotI
    ["", "", "+($1)", "+($1)"], # UnaryPlusI64
    ["", "", "~($1)", "~($1)"], # BitnotI64
    ["", "", "+($1)", "+($1)"], # UnaryPlusF64
    ["", "", "-($1)", "-($1)"], # UnaryMinusF64
    ["", "", "Math.abs($1)", "Math.abs($1)"], # AbsF64
    ["Ze8ToI", "Ze8ToI", "Ze8ToI($1)", "Ze8ToI($1)"], # mZe8ToI
    ["Ze8ToI64", "Ze8ToI64", "Ze8ToI64($1)", "Ze8ToI64($1)"], # mZe8ToI64
    ["Ze16ToI", "Ze16ToI", "Ze16ToI($1)", "Ze16ToI($1)"], # mZe16ToI
    ["Ze16ToI64", "Ze16ToI64", "Ze16ToI64($1)", "Ze16ToI64($1)"], # mZe16ToI64
    ["Ze32ToI64", "Ze32ToI64", "Ze32ToI64($1)", "Ze32ToI64($1)"], # mZe32ToI64
    ["ZeIToI64", "ZeIToI64", "ZeIToI64($1)", "ZeIToI64($1)"], # mZeIToI64
    ["ToU8", "ToU8", "ToU8($1)", "ToU8($1)"], # ToU8
    ["ToU16", "ToU16", "ToU16($1)", "ToU16($1)"], # ToU16
    ["ToU32", "ToU32", "ToU32($1)", "ToU32($1)"], # ToU32
    ["", "", "$1", "$1"],     # ToFloat
    ["", "", "$1", "$1"],     # ToBiggestFloat
    ["", "", "Math.floor($1)", "Math.floor($1)"], # ToInt
    ["", "", "Math.floor($1)", "Math.floor($1)"], # ToBiggestInt
    ["nimCharToStr", "nimCharToStr", "nimCharToStr($1)", "nimCharToStr($1)"], 
    ["nimBoolToStr", "nimBoolToStr", "nimBoolToStr($1)", "nimBoolToStr($1)"], [
      "cstrToNimstr", "cstrToNimstr", "cstrToNimstr(($1)+\"\")", 
      "cstrToNimstr(($1)+\"\")"], ["cstrToNimstr", "cstrToNimstr", 
                                   "cstrToNimstr(($1)+\"\")", 
                                   "cstrToNimstr(($1)+\"\")"], ["cstrToNimstr", 
      "cstrToNimstr", "cstrToNimstr(($1)+\"\")", "cstrToNimstr(($1)+\"\")"], 
    ["cstrToNimstr", "cstrToNimstr", "cstrToNimstr($1)", "cstrToNimstr($1)"], 
    ["", "", "$1", "$1"]]

proc binaryExpr(p: var TProc, n: PNode, r: var TCompRes, magic, frmt: string) = 
  var x, y: TCompRes
  useMagic(p, magic)
  gen(p, n.sons[1], x)
  gen(p, n.sons[2], y)
  r.res = ropef(frmt, [x.res, y.res])
  r.com = mergeExpr(x.com, y.com)

proc binaryStmt(p: var TProc, n: PNode, r: var TCompRes, magic, frmt: string) = 
  var x, y: TCompRes
  useMagic(p, magic)
  gen(p, n.sons[1], x)
  gen(p, n.sons[2], y)
  if x.com != nil: appf(r.com, "$1;$n", [x.com])
  if y.com != nil: appf(r.com, "$1;$n", [y.com])
  appf(r.com, frmt, [x.res, y.res])

proc unaryExpr(p: var TProc, n: PNode, r: var TCompRes, magic, frmt: string) = 
  useMagic(p, magic)
  gen(p, n.sons[1], r)
  r.res = ropef(frmt, [r.res])

proc arith(p: var TProc, n: PNode, r: var TCompRes, op: TMagic) = 
  var 
    x, y: TCompRes
    i: int
  if optOverflowCheck in p.options: i = 0
  else: i = 1
  useMagic(p, ops[op][i])
  if sonsLen(n) > 2: 
    gen(p, n.sons[1], x)
    gen(p, n.sons[2], y)
    r.res = ropef(ops[op][i + 2], [x.res, y.res])
    r.com = mergeExpr(x.com, y.com)
  else: 
    gen(p, n.sons[1], r)
    r.res = ropef(ops[op][i + 2], [r.res])

proc genLineDir(p: var TProc, n: PNode, r: var TCompRes) = 
  var line: int
  line = toLinenumber(n.info)
  if optLineDir in p.Options: 
    appf(r.com, "// line $2 \"$1\"$n", 
         [toRope(toFilename(n.info)), toRope(line)])
  if ({optStackTrace, optEndb} * p.Options == {optStackTrace, optEndb}) and
      ((p.prc == nil) or not (sfPure in p.prc.flags)): 
    useMagic(p, "endb")
    appf(r.com, "endb($1);$n", [toRope(line)])
  elif ({optLineTrace, optStackTrace} * p.Options ==
      {optLineTrace, optStackTrace}) and
      ((p.prc == nil) or not (sfPure in p.prc.flags)): 
    appf(r.com, "F.line = $1;$n", [toRope(line)])
  
proc finishTryStmt(p: var TProc, r: var TCompRes, howMany: int) = 
  for i in countup(1, howMany):
    app(r.com, "excHandler = excHandler.prev;" & tnl)
  
proc genWhileStmt(p: var TProc, n: PNode, r: var TCompRes) = 
  var 
    cond, stmt: TCompRes
    length, labl: int
  genLineDir(p, n, r)
  inc(p.unique)
  length = len(p.blocks)
  setlen(p.blocks, length + 1)
  p.blocks[length].id = - p.unique
  p.blocks[length].nestedTryStmts = p.nestedTryStmts
  p.blocks[length].isLoop = true
  labl = p.unique
  gen(p, n.sons[0], cond)
  genStmt(p, n.sons[1], stmt)
  if p.blocks[length].id > 0: 
    appf(r.com, "L$3: while ($1) {$n$2}$n", 
         [mergeExpr(cond), mergeStmt(stmt), toRope(labl)])
  else: 
    appf(r.com, "while ($1) {$n$2}$n", [mergeExpr(cond), mergeStmt(stmt)])
  setlen(p.blocks, length)

proc genTryStmt(p: var TProc, n: PNode, r: var TCompRes) = 
  # code to generate:
  #
  #  var sp = {prev: excHandler, exc: null};
  #  excHandler = sp;
  #  try {
  #    stmts;
  #  } catch (e) {
  #    if (e.typ && e.typ == NTI433 || e.typ == NTI2321) {
  #      stmts;
  #    } else if (e.typ && e.typ == NTI32342) {
  #      stmts;
  #    } else {
  #      stmts;
  #    }
  #  } finally {
  #    stmts;
  #    excHandler = excHandler.prev;
  #  }
  #
  var 
    i, length, blen: int
    safePoint, orExpr, epart: PRope
    a: TCompRes
  genLineDir(p, n, r)
  inc(p.unique)
  safePoint = ropef("Tmp$1", [toRope(p.unique)])
  appf(r.com, 
       "var $1 = {prev: excHandler, exc: null};$n" & "excHandler = $1;$n", 
       [safePoint])
  if optStackTrace in p.Options: app(r.com, "framePtr = F;" & tnl)
  app(r.com, "try {" & tnl)
  length = sonsLen(n)
  inc(p.nestedTryStmts)
  genStmt(p, n.sons[0], a)
  app(r.com, mergeStmt(a))
  i = 1
  epart = nil
  while (i < length) and (n.sons[i].kind == nkExceptBranch): 
    blen = sonsLen(n.sons[i])
    if blen == 1: 
      # general except section:
      if i > 1: app(epart, "else {" & tnl)
      genStmt(p, n.sons[i].sons[0], a)
      app(epart, mergeStmt(a))
      if i > 1: app(epart, '}' & tnl)
    else: 
      orExpr = nil
      useMagic(p, "isObj")
      for j in countup(0, blen - 2): 
        if (n.sons[i].sons[j].kind != nkType): 
          InternalError(n.info, "genTryStmt")
        if orExpr != nil: app(orExpr, "||")
        appf(orExpr, "isObj($1.exc.m_type, $2)", 
             [safePoint, genTypeInfo(p, n.sons[i].sons[j].typ)])
      if i > 1: app(epart, "else ")
      appf(epart, "if ($1.exc && $2) {$n", [safePoint, orExpr])
      genStmt(p, n.sons[i].sons[blen - 1], a)
      appf(epart, "$1}$n", [mergeStmt(a)])
    inc(i)
  if epart != nil: appf(r.com, "} catch (EXC) {$n$1", [epart])
  finishTryStmt(p, r, p.nestedTryStmts)
  dec(p.nestedTryStmts)
  app(r.com, "} finally {" & tnl & "excHandler = excHandler.prev;" & tnl)
  if (i < length) and (n.sons[i].kind == nkFinally): 
    genStmt(p, n.sons[i].sons[0], a)
    app(r.com, mergeStmt(a))
  app(r.com, '}' & tnl)

proc genRaiseStmt(p: var TProc, n: PNode, r: var TCompRes) = 
  var 
    a: TCompRes
    typ: PType
  genLineDir(p, n, r)
  if n.sons[0].kind != nkEmpty: 
    gen(p, n.sons[0], a)
    if a.com != nil: appf(r.com, "$1;$n", [a.com])
    typ = skipTypes(n.sons[0].typ, abstractPtrs)
    useMagic(p, "raiseException")
    appf(r.com, "raiseException($1, $2);$n", 
         [a.res, makeCString(typ.sym.name.s)])
  else: 
    useMagic(p, "reraiseException")
    app(r.com, "reraiseException();" & tnl)

proc genCaseStmt(p: var TProc, n: PNode, r: var TCompRes) = 
  var 
    cond, stmt: TCompRes
    it, e, v: PNode
    stringSwitch: bool
  genLineDir(p, n, r)
  gen(p, n.sons[0], cond)
  if cond.com != nil: appf(r.com, "$1;$n", [cond.com])
  stringSwitch = skipTypes(n.sons[0].typ, abstractVar).kind == tyString
  if stringSwitch: 
    useMagic(p, "toEcmaStr")
    appf(r.com, "switch (toEcmaStr($1)) {$n", [cond.res])
  else: 
    appf(r.com, "switch ($1) {$n", [cond.res])
  for i in countup(1, sonsLen(n) - 1): 
    it = n.sons[i]
    case it.kind
    of nkOfBranch: 
      for j in countup(0, sonsLen(it) - 2): 
        e = it.sons[j]
        if e.kind == nkRange: 
          v = copyNode(e.sons[0])
          while (v.intVal <= e.sons[1].intVal): 
            gen(p, v, cond)
            if cond.com != nil: internalError(v.info, "ecmasgen.genCaseStmt")
            appf(r.com, "case $1: ", [cond.res])
            Inc(v.intVal)
        else: 
          gen(p, e, cond)
          if cond.com != nil: internalError(e.info, "ecmasgen.genCaseStmt")
          if stringSwitch: 
            case e.kind
            of nkStrLit..nkTripleStrLit: appf(r.com, "case $1: ", 
                [makeCString(e.strVal)])
            else: InternalError(e.info, "ecmasgen.genCaseStmt: 2")
          else: 
            appf(r.com, "case $1: ", [cond.res])
      genStmt(p, lastSon(it), stmt)
      appf(r.com, "$n$1break;$n", [mergeStmt(stmt)])
    of nkElse: 
      genStmt(p, it.sons[0], stmt)
      appf(r.com, "default: $n$1break;$n", [mergeStmt(stmt)])
    else: internalError(it.info, "ecmasgen.genCaseStmt")
  appf(r.com, "}$n", [])

proc genStmtListExpr(p: var TProc, n: PNode, r: var TCompRes)
proc genBlock(p: var TProc, n: PNode, r: var TCompRes) = 
  var 
    idx, labl: int
    sym: PSym
  inc(p.unique)
  idx = len(p.blocks)
  if n.sons[0].kind != nkEmpty: 
    # named block?
    if (n.sons[0].kind != nkSym): InternalError(n.info, "genBlock")
    sym = n.sons[0].sym
    sym.loc.k = locOther
    sym.loc.a = idx
  setlen(p.blocks, idx + 1)
  p.blocks[idx].id = - p.unique # negative because it isn't used yet
  p.blocks[idx].nestedTryStmts = p.nestedTryStmts
  labl = p.unique
  if n.kind == nkBlockExpr: genStmtListExpr(p, n.sons[1], r)
  else: genStmt(p, n.sons[1], r)
  if p.blocks[idx].id > 0: 
    # label has been used:
    r.com = ropef("L$1: do {$n$2} while(false);$n", [toRope(labl), r.com])
  setlen(p.blocks, idx)

proc genBreakStmt(p: var TProc, n: PNode, r: var TCompRes) = 
  var 
    idx: int
    sym: PSym
  genLineDir(p, n, r)
  if n.sons[0].kind != nkEmpty: 
    # named break?
    assert(n.sons[0].kind == nkSym)
    sym = n.sons[0].sym
    assert(sym.loc.k == locOther)
    idx = sym.loc.a
  else:
    # an unnamed 'break' can only break a loop after 'transf' pass:
    idx = len(p.blocks) - 1
    while idx >= 0 and not p.blocks[idx].isLoop: dec idx
    if idx < 0 or not p.blocks[idx].isLoop:
      InternalError(n.info, "no loop to break")
  p.blocks[idx].id = abs(p.blocks[idx].id) # label is used
  finishTryStmt(p, r, p.nestedTryStmts - p.blocks[idx].nestedTryStmts)
  appf(r.com, "break L$1;$n", [toRope(p.blocks[idx].id)])

proc genAsmStmt(p: var TProc, n: PNode, r: var TCompRes) = 
  genLineDir(p, n, r)
  assert(n.kind == nkAsmStmt)
  for i in countup(0, sonsLen(n) - 1): 
    case n.sons[i].Kind
    of nkStrLit..nkTripleStrLit: app(r.com, n.sons[i].strVal)
    of nkSym: app(r.com, mangleName(n.sons[i].sym))
    else: InternalError(n.sons[i].info, "ecmasgen: genAsmStmt()")
  
proc genIfStmt(p: var TProc, n: PNode, r: var TCompRes) = 
  var 
    toClose: int
    cond, stmt: TCompRes
    it: PNode
  toClose = 0
  for i in countup(0, sonsLen(n) - 1): 
    it = n.sons[i]
    if sonsLen(it) != 1: 
      gen(p, it.sons[0], cond)
      genStmt(p, it.sons[1], stmt)
      if i > 0: 
        appf(r.com, "else {$n", [])
        inc(toClose)
      if cond.com != nil: appf(r.com, "$1;$n", [cond.com])
      appf(r.com, "if ($1) {$n$2}", [cond.res, mergeStmt(stmt)])
    else: 
      # else part:
      genStmt(p, it.sons[0], stmt)
      appf(r.com, "else {$n$1}$n", [mergeStmt(stmt)])
  app(r.com, repeatChar(toClose, '}') & tnl)

proc genIfExpr(p: var TProc, n: PNode, r: var TCompRes) = 
  var 
    toClose: int
    cond, stmt: TCompRes
    it: PNode
  toClose = 0
  for i in countup(0, sonsLen(n) - 1): 
    it = n.sons[i]
    if sonsLen(it) != 1: 
      gen(p, it.sons[0], cond)
      gen(p, it.sons[1], stmt)
      if i > 0: 
        app(r.res, ": (")
        inc(toClose)
      r.com = mergeExpr(r.com, cond.com)
      r.com = mergeExpr(r.com, stmt.com)
      appf(r.res, "($1) ? ($2)", [cond.res, stmt.res])
    else: 
      # else part:
      gen(p, it.sons[0], stmt)
      r.com = mergeExpr(r.com, stmt.com)
      appf(r.res, ": ($1)", [stmt.res])
  app(r.res, repeatChar(toClose, ')'))

proc generateHeader(p: var TProc, typ: PType): PRope = 
  var 
    param: PSym
    name: PRope
  result = nil
  for i in countup(1, sonsLen(typ.n) - 1): 
    if result != nil: app(result, ", ")
    assert(typ.n.sons[i].kind == nkSym)
    param = typ.n.sons[i].sym
    name = mangleName(param)
    app(result, name)
    if mapType(param.typ) == etyBaseIndex: 
      app(result, ", ")
      app(result, name)
      app(result, "_Idx")

const 
  nodeKindsNeedNoCopy = {nkCharLit..nkInt64Lit, nkStrLit..nkTripleStrLit, 
    nkFloatLit..nkFloat64Lit, nkCurly, nkPar, nkStringToCString, 
    nkCStringToString, nkCall, nkPrefix, nkPostfix, nkInfix, 
    nkCommand, nkHiddenCallConv, nkCallStrLit}

proc needsNoCopy(y: PNode): bool = 
  result = (y.kind in nodeKindsNeedNoCopy) or
      (skipTypes(y.typ, abstractInst).kind in {tyRef, tyPtr, tyVar})

proc genAsgnAux(p: var TProc, x, y: PNode, r: var TCompRes, 
                noCopyNeeded: bool) = 
  var a, b: TCompRes
  gen(p, x, a)
  gen(p, y, b)
  case mapType(x.typ)
  of etyObject: 
    if a.com != nil: appf(r.com, "$1;$n", [a.com])
    if b.com != nil: appf(r.com, "$1;$n", [b.com])
    if needsNoCopy(y) or noCopyNeeded: 
      appf(r.com, "$1 = $2;$n", [a.res, b.res])
    else: 
      useMagic(p, "NimCopy")
      appf(r.com, "$1 = NimCopy($2, $3);$n", 
           [a.res, b.res, genTypeInfo(p, y.typ)])
  of etyBaseIndex: 
    if (a.kind != etyBaseIndex) or (b.kind != etyBaseIndex): 
      internalError(x.info, "genAsgn")
    appf(r.com, "$1 = $2; $3 = $4;$n", [a.com, b.com, a.res, b.res])
  else: 
    if a.com != nil: appf(r.com, "$1;$n", [a.com])
    if b.com != nil: appf(r.com, "$1;$n", [b.com])
    appf(r.com, "$1 = $2;$n", [a.res, b.res])

proc genAsgn(p: var TProc, n: PNode, r: var TCompRes) = 
  genLineDir(p, n, r)
  genAsgnAux(p, n.sons[0], n.sons[1], r, false)

proc genFastAsgn(p: var TProc, n: PNode, r: var TCompRes) = 
  genLineDir(p, n, r)
  genAsgnAux(p, n.sons[0], n.sons[1], r, true)

proc genSwap(p: var TProc, n: PNode, r: var TCompRes) = 
  var a, b: TCompRes
  gen(p, n.sons[1], a)
  gen(p, n.sons[2], b)
  inc(p.unique)
  var tmp = ropef("Tmp$1", [toRope(p.unique)])
  case mapType(skipTypes(n.sons[1].typ, abstractVar))
  of etyBaseIndex: 
    inc(p.unique)
    var tmp2 = ropef("Tmp$1", [toRope(p.unique)])
    if (a.kind != etyBaseIndex) or (b.kind != etyBaseIndex): 
      internalError(n.info, "genSwap")
    appf(r.com, "var $1 = $2; $2 = $3; $3 = $1;$n", [tmp, a.com, b.com])
    appf(r.com, "var $1 = $2; $2 = $3; $3 = $1", [tmp2, a.res, b.res])
  else: 
    if a.com != nil: appf(r.com, "$1;$n", [a.com])
    if b.com != nil: appf(r.com, "$1;$n", [b.com])
    appf(r.com, "var $1 = $2; $2 = $3; $3 = $1", [tmp, a.res, b.res])

proc getFieldPosition(f: PNode): int =
  case f.kind
  of nkIntLit..nkUInt64Lit: result = int(f.intVal)
  of nkSym: result = f.sym.position
  else: InternalError(f.info, "genFieldPosition")

proc genFieldAddr(p: var TProc, n: PNode, r: var TCompRes) = 
  var a: TCompRes
  r.kind = etyBaseIndex
  var b = if n.kind == nkHiddenAddr: n.sons[0] else: n
  gen(p, b.sons[0], a)
  if skipTypes(b.sons[0].typ, abstractVarRange).kind == tyTuple:
    r.res = makeCString("Field" & $getFieldPosition(b.sons[1]))
  else:
    if b.sons[1].kind != nkSym: InternalError(b.sons[1].info, "genFieldAddr")
    var f = b.sons[1].sym
    if f.loc.r == nil: f.loc.r = mangleName(f)
    r.res = makeCString(ropeToStr(f.loc.r))
  r.com = mergeExpr(a)

proc genFieldAccess(p: var TProc, n: PNode, r: var TCompRes) = 
  r.kind = etyNone
  gen(p, n.sons[0], r)
  if skipTypes(n.sons[0].typ, abstractVarRange).kind == tyTuple:
    r.res = ropef("$1.Field$2", [r.res, getFieldPosition(n.sons[1]).toRope])
  else:
    if n.sons[1].kind != nkSym: InternalError(n.sons[1].info, "genFieldAddr")
    var f = n.sons[1].sym
    if f.loc.r == nil: f.loc.r = mangleName(f)
    r.res = ropef("$1.$2", [r.res, f.loc.r])

proc genCheckedFieldAddr(p: var TProc, n: PNode, r: var TCompRes) = 
  genFieldAddr(p, n.sons[0], r) # XXX
  
proc genCheckedFieldAccess(p: var TProc, n: PNode, r: var TCompRes) = 
  genFieldAccess(p, n.sons[0], r) # XXX
  
proc genArrayAddr(p: var TProc, n: PNode, r: var TCompRes) = 
  var 
    a, b: TCompRes
    first: biggestInt
  r.kind = etyBaseIndex
  gen(p, n.sons[0], a)
  gen(p, n.sons[1], b)
  r.com = mergeExpr(a)
  var typ = skipTypes(n.sons[0].typ, abstractPtrs)
  if typ.kind in {tyArray, tyArrayConstr}: first = FirstOrd(typ.sons[0])
  else: first = 0
  if optBoundsCheck in p.options and not isConstExpr(n.sons[1]): 
    useMagic(p, "chckIndx")
    b.res = ropef("chckIndx($1, $2, $3.length)-$2", 
                  [b.res, toRope(first), a.res]) 
    # XXX: BUG: a.res evaluated twice!
  elif first != 0: 
    b.res = ropef("($1)-$2", [b.res, toRope(first)])
  r.res = mergeExpr(b)

proc genArrayAccess(p: var TProc, n: PNode, r: var TCompRes) = 
  var ty = skipTypes(n.sons[0].typ, abstractVarRange)
  if ty.kind in {tyRef, tyPtr}: ty = skipTypes(ty.sons[0], abstractVarRange)
  case ty.kind
  of tyArray, tyArrayConstr, tyOpenArray, tySequence, tyString, tyCString: 
    genArrayAddr(p, n, r)
  of tyTuple: 
    genFieldAddr(p, n, r)
  else: InternalError(n.info, "expr(nkBracketExpr, " & $ty.kind & ')')
  r.kind = etyNone
  r.res = ropef("$1[$2]", [r.com, r.res])
  r.com = nil

proc genAddr(p: var TProc, n: PNode, r: var TCompRes) = 
  var s: PSym
  case n.sons[0].kind
  of nkSym: 
    s = n.sons[0].sym
    if s.loc.r == nil: InternalError(n.info, "genAddr: 3")
    case s.kind
    of skVar, skLet, skResult: 
      if mapType(n.typ) == etyObject: 
        # make addr() a no-op:
        r.kind = etyNone
        r.res = s.loc.r
        r.com = nil
      elif sfGlobal in s.flags: 
        # globals are always indirect accessible
        r.kind = etyBaseIndex
        r.com = toRope("Globals")
        r.res = makeCString(ropeToStr(s.loc.r))
      elif sfAddrTaken in s.flags: 
        r.kind = etyBaseIndex
        r.com = s.loc.r
        r.res = toRope("0")
      else: 
        InternalError(n.info, "genAddr: 4")
    else: InternalError(n.info, "genAddr: 2")
  of nkCheckedFieldExpr: 
    genCheckedFieldAddr(p, n, r)
  of nkDotExpr: 
    genFieldAddr(p, n, r)
  of nkBracketExpr:
    var ty = skipTypes(n.sons[0].typ, abstractVarRange)
    if ty.kind in {tyRef, tyPtr}: ty = skipTypes(ty.sons[0], abstractVarRange)
    case ty.kind
    of tyArray, tyArrayConstr, tyOpenArray, tySequence, tyString, tyCString: 
      genArrayAddr(p, n, r)
    of tyTuple: 
      genFieldAddr(p, n, r)
    else: InternalError(n.info, "expr(nkBracketExpr, " & $ty.kind & ')')
  else: InternalError(n.info, "genAddr")
  
proc genSym(p: var TProc, n: PNode, r: var TCompRes) = 
  var s = n.sym
  case s.kind
  of skVar, skLet, skParam, skTemp, skResult: 
    if s.loc.r == nil: 
      InternalError(n.info, "symbol has no generated name: " & s.name.s)
    var k = mapType(s.typ)
    if k == etyBaseIndex: 
      r.kind = etyBaseIndex
      if {sfAddrTaken, sfGlobal} * s.flags != {}: 
        r.com = ropef("$1[0]", [s.loc.r])
        r.res = ropef("$1[1]", [s.loc.r])
      else: 
        r.com = s.loc.r
        r.res = con(s.loc.r, "_Idx")
    elif (k != etyObject) and (sfAddrTaken in s.flags): 
      r.res = ropef("$1[0]", [s.loc.r])
    else: 
      r.res = s.loc.r
  of skConst:
    genConstant(p, s, r)
    if s.loc.r == nil:
      InternalError(n.info, "symbol has no generated name: " & s.name.s)
    r.res = s.loc.r
  of skProc, skConverter, skMethod:
    discard mangleName(s)
    r.res = s.loc.r
    if lfNoDecl in s.loc.flags or s.magic != mNone or isGenericRoutine(s): nil
    elif s.kind == skMethod and s.getBody.kind == nkEmpty:
      # we cannot produce code for the dispatcher yet:
      nil
    elif sfForward in s.flags:
      p.g.forwarded.add(s)
    elif not p.g.generatedSyms.containsOrIncl(s.id):
      var r2: TCompRes
      genProc(p, s, r2)
      app(p.g.code, mergeStmt(r2))
  else:
    if s.loc.r == nil:
      InternalError(n.info, "symbol has no generated name: " & s.name.s)
    r.res = s.loc.r
  
proc genDeref(p: var TProc, n: PNode, r: var TCompRes) = 
  var a: TCompRes
  if mapType(n.sons[0].typ) == etyObject: 
    gen(p, n.sons[0], r)
  else: 
    gen(p, n.sons[0], a)
    if a.kind != etyBaseIndex: InternalError(n.info, "genDeref")
    r.res = ropef("$1[$2]", [a.com, a.res])

proc genArgs(p: var TProc, n: PNode, r: var TCompRes) =
  app(r.res, "(")
  for i in countup(1, sonsLen(n) - 1): 
    if i > 1: app(r.res, ", ")
    var a: TCompRes
    gen(p, n.sons[i], a)
    if a.kind == etyBaseIndex: 
      app(r.res, a.com)
      app(r.res, ", ")
      app(r.res, a.res)
    else: 
      app(r.res, mergeExpr(a))
  app(r.res, ")")

proc genCall(p: var TProc, n: PNode, r: var TCompRes) = 
  gen(p, n.sons[0], r)
  genArgs(p, n, r)

proc genEcho(p: var TProc, n: PNode, r: var TCompRes) =
  useMagic(p, "rawEcho")
  app(r.res, "rawEcho")
  genArgs(p, n, r)

proc putToSeq(s: string, indirect: bool): PRope = 
  result = toRope(s)
  if indirect: result = ropef("[$1]", [result])
  
proc createVar(p: var TProc, typ: PType, indirect: bool): PRope
proc createRecordVarAux(p: var TProc, rec: PNode, c: var int): PRope = 
  result = nil
  case rec.kind
  of nkRecList: 
    for i in countup(0, sonsLen(rec) - 1): 
      app(result, createRecordVarAux(p, rec.sons[i], c))
  of nkRecCase: 
    app(result, createRecordVarAux(p, rec.sons[0], c))
    for i in countup(1, sonsLen(rec) - 1): 
      app(result, createRecordVarAux(p, lastSon(rec.sons[i]), c))
  of nkSym: 
    if c > 0: app(result, ", ")
    app(result, mangleName(rec.sym))
    app(result, ": ")
    app(result, createVar(p, rec.sym.typ, false))
    inc(c)
  else: InternalError(rec.info, "createRecordVarAux")
  
proc createVar(p: var TProc, typ: PType, indirect: bool): PRope = 
  var t = skipTypes(typ, abstractInst)
  case t.kind
  of tyInt..tyInt64, tyEnum, tyChar: 
    result = putToSeq("0", indirect)
  of tyFloat..tyFloat128: 
    result = putToSeq("0.0", indirect)
  of tyRange, tyGenericInst: 
    result = createVar(p, lastSon(typ), indirect)
  of tySet: 
    result = toRope("{}")
  of tyBool: 
    result = putToSeq("false", indirect)
  of tyArray, tyArrayConstr: 
    var length = int(lengthOrd(t))
    var e = elemType(t)
    if length > 32: 
      useMagic(p, "ArrayConstr")
      result = ropef("ArrayConstr($1, $2, $3)", [toRope(length), 
          createVar(p, e, false), genTypeInfo(p, e)])
    else: 
      result = toRope("[")
      var i = 0
      while i < length: 
        if i > 0: app(result, ", ")
        app(result, createVar(p, e, false))
        inc(i)
      app(result, "]")
  of tyTuple: 
    result = toRope("{")
    for i in 0.. <t.sonslen:
      if i > 0: app(result, ", ")
      appf(result, "Field$1: $2", i.toRope, createVar(p, t.sons[i], false))
    app(result, "}")
  of tyObject: 
    result = toRope("{")
    var c = 0
    if not (tfFinal in t.flags) or (t.sons[0] != nil): 
      inc(c)
      appf(result, "m_type: $1", [genTypeInfo(p, t)])
    while t != nil: 
      app(result, createRecordVarAux(p, t.n, c))
      t = t.sons[0]
    app(result, "}")
  of tyVar, tyPtr, tyRef: 
    if mapType(t) == etyBaseIndex: result = putToSeq("[null, 0]", indirect)
    else: result = putToSeq("null", indirect)
  of tySequence, tyString, tyCString, tyPointer, tyProc: 
    result = putToSeq("null", indirect)
  else: 
    internalError("createVar: " & $t.kind)
    result = nil

proc isIndirect(v: PSym): bool = 
  result = (sfAddrTaken in v.flags) and (mapType(v.typ) != etyObject) and
    v.kind notin {skProc, skConverter, skMethod, skIterator}

proc genVarInit(p: var TProc, v: PSym, n: PNode, r: var TCompRes) = 
  var 
    a: TCompRes
    s: PRope
  if n.kind == nkEmpty: 
    appf(r.com, "var $1 = $2;$n", 
         [mangleName(v), createVar(p, v.typ, isIndirect(v))])
  else: 
    discard mangleName(v)
    gen(p, n, a)
    case mapType(v.typ)
    of etyObject: 
      if a.com != nil: appf(r.com, "$1;$n", [a.com])
      if needsNoCopy(n): 
        s = a.res
      else: 
        useMagic(p, "NimCopy")
        s = ropef("NimCopy($1, $2)", [a.res, genTypeInfo(p, n.typ)])
    of etyBaseIndex: 
      if (a.kind != etyBaseIndex): InternalError(n.info, "genVarInit")
      if {sfAddrTaken, sfGlobal} * v.flags != {}: 
        appf(r.com, "var $1 = [$2, $3];$n", [v.loc.r, a.com, a.res])
      else: 
        appf(r.com, "var $1 = $2; var $1_Idx = $3;$n", [v.loc.r, a.com, a.res])
      return 
    else: 
      if a.com != nil: appf(r.com, "$1;$n", [a.com])
      s = a.res
    if isIndirect(v): appf(r.com, "var $1 = [$2];$n", [v.loc.r, s])
    else: appf(r.com, "var $1 = $2;$n", [v.loc.r, s])
  
proc genVarStmt(p: var TProc, n: PNode, r: var TCompRes) = 
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if a.kind == nkCommentStmt: continue 
    assert(a.kind == nkIdentDefs)
    assert(a.sons[0].kind == nkSym)
    var v = a.sons[0].sym
    if lfNoDecl in v.loc.flags: continue 
    genLineDir(p, a, r)
    genVarInit(p, v, a.sons[2], r)

proc genConstant(p: var TProc, c: PSym, r: var TCompRes) =
  if lfNoDecl notin c.loc.flags and not p.g.generatedSyms.containsOrIncl(c.id):
    genLineDir(p, c.ast, r)
    genVarInit(p, c, c.ast, r)

when false:
  proc genConstStmt(p: var TProc, n: PNode, r: var TCompRes) =
    genLineDir(p, n, r)
    for i in countup(0, sonsLen(n) - 1):
      if n.sons[i].kind == nkCommentStmt: continue
      assert(n.sons[i].kind == nkConstDef)
      var c = n.sons[i].sons[0].sym
      if c.ast != nil and c.typ.kind in ConstantDataTypes and
          lfNoDecl notin c.loc.flags:
        genLineDir(p, n.sons[i], r)
        genVarInit(p, c, c.ast, r)

proc genNew(p: var TProc, n: PNode, r: var TCompRes) =
  var a: TCompRes
  gen(p, n.sons[1], a)
  var t = skipTypes(n.sons[1].typ, abstractVar).sons[0]
  if a.com != nil: appf(r.com, "$1;$n", [a.com])
  appf(r.com, "$1 = $2;$n", [a.res, createVar(p, t, true)])

proc genNewSeq(p: var TProc, n: PNode, r: var TCompRes) =
  var x, y: TCompRes
  gen(p, n.sons[1], x)
  gen(p, n.sons[2], y)
  if x.com != nil: appf(r.com, "$1;$n", [x.com])
  if y.com != nil: appf(r.com, "$1;$n", [y.com])
  var t = skipTypes(n.sons[1].typ, abstractVar).sons[0]
  appf(r.com, "$1 = new Array($2); for (var i=0;i<$2;++i) {$1[i]=$3;}", [
    x.res, y.res, createVar(p, t, false)])

proc genOrd(p: var TProc, n: PNode, r: var TCompRes) =
  case skipTypes(n.sons[1].typ, abstractVar).kind
  of tyEnum, tyInt..tyInt64, tyChar: gen(p, n.sons[1], r)
  of tyBool: unaryExpr(p, n, r, "", "($1 ? 1:0)")
  else: InternalError(n.info, "genOrd")
  
proc genConStrStr(p: var TProc, n: PNode, r: var TCompRes) =
  var a: TCompRes

  gen(p, n.sons[1], a)
  r.com = mergeExpr(r.com, a.com)
  if skipTypes(n.sons[1].typ, abstractVarRange).kind == tyChar:
    r.res.app(ropef("[$1].concat(", [a.res]))
  else:
    r.res.app(ropef("($1.slice(0,-1)).concat(", [a.res]))

  for i in countup(2, sonsLen(n) - 2):
    gen(p, n.sons[i], a)
    r.com = mergeExpr(r.com, a.com)

    if skipTypes(n.sons[i].typ, abstractVarRange).kind == tyChar:
      r.res.app(ropef("[$1],", [a.res]))
    else:
      r.res.app(ropef("$1.slice(0,-1),", [a.res]))

  gen(p, n.sons[sonsLen(n) - 1], a)
  r.com = mergeExpr(r.com, a.com)
  if skipTypes(n.sons[sonsLen(n) - 1].typ, abstractVarRange).kind == tyChar:
    r.res.app(ropef("[$1, 0])", [a.res]))
  else:
    r.res.app(ropef("$1)", [a.res]))

proc genRepr(p: var TProc, n: PNode, r: var TCompRes) =
  var t = skipTypes(n.sons[1].typ, abstractVarRange)
  case t.kind
  of tyInt..tyInt64:
    unaryExpr(p, n, r, "", "reprInt($1)")
  of tyEnum, tyOrdinal:
    binaryExpr(p, n, r, "", "reprEnum($1, $2)")
  else:
    # XXX:
    internalError(n.info, "genRepr: Not implemented")

proc genOf(p: var TProc, n: PNode, r: var TCompRes) =
  var x: TCompRes
  let t = skipTypes(n.sons[2].typ, abstractVarRange+{tyRef, tyPtr})
  gen(p, n.sons[1], x)
  if tfFinal in t.flags:
    r.res = ropef("($1.m_type == $2)", [x.res, genTypeInfo(p, t)])
  else:
    useMagic(p, "isObj")
    r.res = ropef("isObj($1.m_type, $2)", [x.res, genTypeInfo(p, t)])
  r.com = mergeExpr(r.com, x.com)

proc genReset(p: var TProc, n: PNode, r: var TCompRes) =
  var x: TCompRes
  useMagic(p, "genericReset")
  gen(p, n.sons[1], x)
  r.res = ropef("$1 = genericReset($1, $2)", [x.res, 
                genTypeInfo(p, n.sons[1].typ)])
  r.com = mergeExpr(r.com, x.com)

proc genMagic(p: var TProc, n: PNode, r: var TCompRes) =
  var 
    a: TCompRes
    line, filen: PRope
  var op = n.sons[0].sym.magic
  case op
  of mOr: genOr(p, n.sons[1], n.sons[2], r)
  of mAnd: genAnd(p, n.sons[1], n.sons[2], r)
  of mAddi..mStrToStr: arith(p, n, r, op)
  of mRepr: genRepr(p, n, r)
  of mSwap: genSwap(p, n, r)
  of mUnaryLt:
    # XXX: range checking?
    if not (optOverflowCheck in p.Options): unaryExpr(p, n, r, "", "$1 - 1")
    else: unaryExpr(p, n, r, "subInt", "subInt($1, 1)")
  of mPred:
    # XXX: range checking?
    if not (optOverflowCheck in p.Options): binaryExpr(p, n, r, "", "$1 - $2")
    else: binaryExpr(p, n, r, "subInt", "subInt($1, $2)")
  of mSucc:
    # XXX: range checking?
    if not (optOverflowCheck in p.Options): binaryExpr(p, n, r, "", "$1 - $2")
    else: binaryExpr(p, n, r, "addInt", "addInt($1, $2)")
  of mAppendStrCh: binaryStmt(p, n, r, "addChar", "$1 = addChar($1, $2)")
  of mAppendStrStr:
    if skipTypes(n.sons[1].typ, abstractVarRange).kind == tyCString:
        binaryStmt(p, n, r, "", "$1 += $2")
    else:
      binaryStmt(p, n, r, "", "$1 = ($1.slice(0,-1)).concat($2)")
    # XXX: make a copy of $2, because of ECMAScript's sucking semantics
  of mAppendSeqElem: binaryStmt(p, n, r, "", "$1.push($2)")
  of mConStrStr: genConStrStr(p, n, r)
  of mEqStr: binaryExpr(p, n, r, "eqStrings", "eqStrings($1, $2)")
  of mLeStr: binaryExpr(p, n, r, "cmpStrings", "(cmpStrings($1, $2) <= 0)")
  of mLtStr: binaryExpr(p, n, r, "cmpStrings", "(cmpStrings($1, $2) < 0)")
  of mIsNil: unaryExpr(p, n, r, "", "$1 == null")
  of mEnumToStr: genRepr(p, n, r)
  of mNew, mNewFinalize: genNew(p, n, r)
  of mSizeOf: r.res = toRope(getSize(n.sons[1].typ))
  of mChr, mArrToSeq: gen(p, n.sons[1], r)      # nothing to do
  of mOrd: genOrd(p, n, r)
  of mLengthStr: unaryExpr(p, n, r, "", "($1.length-1)")
  of mLengthSeq, mLengthOpenArray, mLengthArray:
    unaryExpr(p, n, r, "", "$1.length")
  of mHigh:
    if skipTypes(n.sons[0].typ, abstractVar).kind == tyString:
      unaryExpr(p, n, r, "", "($1.length-2)")
    else:
      unaryExpr(p, n, r, "", "($1.length-1)")
  of mInc:
    if not (optOverflowCheck in p.Options): binaryStmt(p, n, r, "", "$1 += $2")
    else: binaryStmt(p, n, r, "addInt", "$1 = addInt($1, $2)")
  of ast.mDec:
    if not (optOverflowCheck in p.Options): binaryStmt(p, n, r, "", "$1 -= $2")
    else: binaryStmt(p, n, r, "subInt", "$1 = subInt($1, $2)")
  of mSetLengthStr: binaryStmt(p, n, r, "", "$1.length = ($2)-1")
  of mSetLengthSeq: binaryStmt(p, n, r, "", "$1.length = $2")
  of mCard: unaryExpr(p, n, r, "SetCard", "SetCard($1)")
  of mLtSet: binaryExpr(p, n, r, "SetLt", "SetLt($1, $2)")
  of mLeSet: binaryExpr(p, n, r, "SetLe", "SetLe($1, $2)")
  of mEqSet: binaryExpr(p, n, r, "SetEq", "SetEq($1, $2)")
  of mMulSet: binaryExpr(p, n, r, "SetMul", "SetMul($1, $2)")
  of mPlusSet: binaryExpr(p, n, r, "SetPlus", "SetPlus($1, $2)")
  of mMinusSet: binaryExpr(p, n, r, "SetMinus", "SetMinus($1, $2)")
  of mIncl: binaryStmt(p, n, r, "", "$1[$2] = true")
  of mExcl: binaryStmt(p, n, r, "", "delete $1[$2]")
  of mInSet: binaryExpr(p, n, r, "", "($1[$2] != undefined)")
  of mNLen..mNError:
    localError(n.info, errCannotGenerateCodeForX, n.sons[0].sym.name.s)
  of mNewSeq: genNewSeq(p, n, r)
  of mOf: genOf(p, n, r)
  of mReset: genReset(p, n, r)
  of mEcho: genEcho(p, n, r)
  of mSlurp, mStaticExec:
    localError(n.info, errXMustBeCompileTime, n.sons[0].sym.name.s)
  else:
    genCall(p, n, r)
    #else internalError(e.info, 'genMagic: ' + magicToStr[op]);
  
proc genSetConstr(p: var TProc, n: PNode, r: var TCompRes) = 
  var 
    a, b: TCompRes
  useMagic(p, "SetConstr")
  r.res = toRope("SetConstr(")
  for i in countup(0, sonsLen(n) - 1): 
    if i > 0: app(r.res, ", ")
    var it = n.sons[i]
    if it.kind == nkRange: 
      gen(p, it.sons[0], a)
      gen(p, it.sons[1], b)
      r.com = mergeExpr(r.com, mergeExpr(a.com, b.com))
      appf(r.res, "[$1, $2]", [a.res, b.res])
    else: 
      gen(p, it, a)
      r.com = mergeExpr(r.com, a.com)
      app(r.res, a.res)
  app(r.res, ")")

proc genArrayConstr(p: var TProc, n: PNode, r: var TCompRes) = 
  var a: TCompRes
  r.res = toRope("[")
  for i in countup(0, sonsLen(n) - 1): 
    if i > 0: app(r.res, ", ")
    gen(p, n.sons[i], a)
    r.com = mergeExpr(r.com, a.com)
    app(r.res, a.res)
  app(r.res, "]")

proc genTupleConstr(p: var TProc, n: PNode, r: var TCompRes) = 
  var a: TCompRes
  r.res = toRope("{")
  for i in countup(0, sonsLen(n) - 1):
    if i > 0: app(r.res, ", ")
    var it = n.sons[i]
    if it.kind == nkExprColonExpr: it = it.sons[1]
    gen(p, it, a)
    r.com = mergeExpr(r.com, a.com)
    appf(r.res, "Field$1: $2", [i.toRope, a.res])
  r.res.app("}")

proc genConv(p: var TProc, n: PNode, r: var TCompRes) = 
  var dest = skipTypes(n.typ, abstractVarRange)
  var src = skipTypes(n.sons[1].typ, abstractVarRange)
  gen(p, n.sons[1], r)
  if (dest.kind != src.kind) and (src.kind == tyBool): 
    r.res = ropef("(($1)? 1:0)", [r.res])
  
proc upConv(p: var TProc, n: PNode, r: var TCompRes) = 
  gen(p, n.sons[0], r)        # XXX
  
proc genRangeChck(p: var TProc, n: PNode, r: var TCompRes, magic: string) = 
  var a, b: TCompRes
  gen(p, n.sons[0], r)
  if optRangeCheck in p.options: 
    gen(p, n.sons[1], a)
    gen(p, n.sons[2], b)
    r.com = mergeExpr(r.com, mergeExpr(a.com, b.com))
    useMagic(p, "chckRange")
    r.res = ropef("chckRange($1, $2, $3)", [r.res, a.res, b.res])

proc convStrToCStr(p: var TProc, n: PNode, r: var TCompRes) = 
  # we do an optimization here as this is likely to slow down
  # much of the code otherwise:
  if n.sons[0].kind == nkCStringToString: 
    gen(p, n.sons[0].sons[0], r)
  else: 
    gen(p, n.sons[0], r)
    if r.res == nil: InternalError(n.info, "convStrToCStr")
    useMagic(p, "toEcmaStr")
    r.res = ropef("toEcmaStr($1)", [r.res])

proc convCStrToStr(p: var TProc, n: PNode, r: var TCompRes) = 
  # we do an optimization here as this is likely to slow down
  # much of the code otherwise:
  if n.sons[0].kind == nkStringToCString: 
    gen(p, n.sons[0].sons[0], r)
  else: 
    gen(p, n.sons[0], r)
    if r.res == nil: InternalError(n.info, "convCStrToStr")
    useMagic(p, "cstrToNimstr")
    r.res = ropef("cstrToNimstr($1)", [r.res])

proc genReturnStmt(p: var TProc, n: PNode, r: var TCompRes) = 
  var a: TCompRes
  if p.procDef == nil: InternalError(n.info, "genReturnStmt")
  p.BeforeRetNeeded = true
  if (n.sons[0].kind != nkEmpty): 
    genStmt(p, n.sons[0], a)
    if a.com != nil: appf(r.com, "$1;$n", mergeStmt(a))
  else: 
    genLineDir(p, n, r)
  finishTryStmt(p, r, p.nestedTryStmts)
  app(r.com, "break BeforeRet;" & tnl)

proc genProcBody(p: var TProc, prc: PSym, r: TCompRes): PRope = 
  if optStackTrace in prc.options: 
    result = ropef("var F={procname:$1,prev:framePtr,filename:$2,line:0};$n" &
        "framePtr = F;$n", [makeCString(prc.owner.name.s & '.' & prc.name.s), 
                            makeCString(toFilename(prc.info))])
  else: 
    result = nil
  if p.beforeRetNeeded: 
    appf(result, "BeforeRet: do {$n$1} while (false); $n", [mergeStmt(r)])
  else: 
    app(result, mergeStmt(r))
  if prc.typ.callConv == ccSysCall: 
    result = ropef("try {$n$1} catch (e) {$n" &
        " alert(\"Unhandled exception:\\n\" + e.message + \"\\n\"$n}", [result])
  if optStackTrace in prc.options: 
    app(result, "framePtr = framePtr.prev;" & tnl)

proc genProc(oldProc: var TProc, prc: PSym, r: var TCompRes) = 
  var 
    p: TProc
    resultSym: PSym
    name, returnStmt, resultAsgn, header: PRope
    a: TCompRes
  #if gVerbosity >= 3: 
  #  echo "BEGIN generating code for: " & prc.name.s
  initProc(p, oldProc.g, oldProc.module, prc.ast, prc.options)
  returnStmt = nil
  resultAsgn = nil
  name = mangleName(prc)
  header = generateHeader(p, prc.typ)
  if (prc.typ.sons[0] != nil) and sfPure notin prc.flags: 
    resultSym = prc.ast.sons[resultPos].sym
    resultAsgn = ropef("var $1 = $2;$n", [mangleName(resultSym), 
        createVar(p, resultSym.typ, isIndirect(resultSym))])
    gen(p, prc.ast.sons[resultPos], a)
    if a.com != nil: appf(returnStmt, "$1;$n", [a.com])
    returnStmt = ropef("return $1;$n", [a.res])
  genStmt(p, prc.getBody, r)
  r.com = ropef("function $1($2) {$n$3$4$5}$n", 
                [name, header, resultAsgn, genProcBody(p, prc, r), returnStmt])
  r.res = nil  
  #if gVerbosity >= 3:
  #  echo "END   generated code for: " & prc.name.s
  
proc genStmtListExpr(p: var TProc, n: PNode, r: var TCompRes) = 
  var a: TCompRes
  # watch out this trick: ``function () { stmtList; return expr; }()``
  r.res = toRope("function () {")
  for i in countup(0, sonsLen(n) - 2): 
    genStmt(p, n.sons[i], a)
    app(r.res, mergeStmt(a))
  gen(p, lastSon(n), a)
  if a.com != nil: appf(r.res, "$1;$n", [a.com])
  appf(r.res, "return $1; }()", [a.res])

proc genStmt(p: var TProc, n: PNode, r: var TCompRes) = 
  var a: TCompRes
  r.kind = etyNone
  r.com = nil
  r.res = nil
  case n.kind
  of nkNilLit, nkEmpty: nil
  of nkStmtList: 
    for i in countup(0, sonsLen(n) - 1): 
      genStmt(p, n.sons[i], a)
      app(r.com, mergeStmt(a))
  of nkBlockStmt: genBlock(p, n, r)
  of nkIfStmt: genIfStmt(p, n, r)
  of nkWhileStmt: genWhileStmt(p, n, r)
  of nkVarSection, nkLetSection: genVarStmt(p, n, r)
  of nkConstSection: nil
  of nkForStmt, nkParForStmt: 
    internalError(n.info, "for statement not eliminated")
  of nkCaseStmt: genCaseStmt(p, n, r)
  of nkReturnStmt: genReturnStmt(p, n, r)
  of nkBreakStmt: genBreakStmt(p, n, r)
  of nkAsgn: genAsgn(p, n, r)
  of nkFastAsgn: genFastAsgn(p, n, r)
  of nkDiscardStmt: 
    genLineDir(p, n, r)
    gen(p, n.sons[0], r)
    app(r.res, ';' & tnl)
  of nkAsmStmt: genAsmStmt(p, n, r)
  of nkTryStmt: genTryStmt(p, n, r)
  of nkRaiseStmt: genRaiseStmt(p, n, r)
  of nkTypeSection, nkCommentStmt, nkIteratorDef, nkIncludeStmt, nkImportStmt, 
     nkFromStmt, nkTemplateDef, nkMacroDef, nkPragma: nil
  of nkProcDef, nkMethodDef, nkConverterDef:
    var s = n.sons[namePos].sym
    if {sfExportc, sfCompilerProc} * s.flags == {sfExportc}: 
      var r2: TCompRes
      genSym(p, n.sons[namePos], r2)
  else:
    genLineDir(p, n, r)
    gen(p, n, r)
    app(r.res, ';' & tnl)

proc gen(p: var TProc, n: PNode, r: var TCompRes) = 
  var f: BiggestFloat
  r.kind = etyNone
  r.com = nil
  r.res = nil
  case n.kind
  of nkSym: 
    genSym(p, n, r)
  of nkCharLit..nkInt64Lit: 
    r.res = toRope(n.intVal)
  of nkNilLit: 
    if mapType(n.typ) == etyBaseIndex: 
      r.kind = etyBaseIndex
      r.com = toRope"null"
      r.res = toRope"0"
    else: 
      r.res = toRope"null"
  of nkStrLit..nkTripleStrLit: 
    if skipTypes(n.typ, abstractVarRange).kind == tyString: 
      useMagic(p, "cstrToNimstr")
      r.res = ropef("cstrToNimstr($1)", [makeCString(n.strVal)])
    else: 
      r.res = makeCString(n.strVal)
  of nkFloatLit..nkFloat64Lit: 
    f = n.floatVal
    if f != f: r.res = toRope"NaN"
    elif f == 0.0: r.res = toRope"0.0"
    elif f == 0.5 * f: 
      if f > 0.0: r.res = toRope"Infinity"
      else: r.res = toRope"-Infinity"
    else: r.res = toRope(f.ToStrMaxPrecision)
  of nkBlockExpr: genBlock(p, n, r)
  of nkIfExpr: genIfExpr(p, n, r)
  of nkCallKinds: 
    if (n.sons[0].kind == nkSym) and (n.sons[0].sym.magic != mNone): 
      genMagic(p, n, r)
    else: 
      genCall(p, n, r)
  of nkCurly: genSetConstr(p, n, r)
  of nkBracket: genArrayConstr(p, n, r)
  of nkPar: genTupleConstr(p, n, r)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv: genConv(p, n, r)
  of nkAddr, nkHiddenAddr: genAddr(p, n, r)
  of nkDerefExpr, nkHiddenDeref: genDeref(p, n, r)
  of nkBracketExpr: genArrayAccess(p, n, r)
  of nkDotExpr: genFieldAccess(p, n, r)
  of nkCheckedFieldExpr: genCheckedFieldAccess(p, n, r)
  of nkObjDownConv: gen(p, n.sons[0], r)
  of nkObjUpConv: upConv(p, n, r)
  of nkChckRangeF: genRangeChck(p, n, r, "chckRangeF")
  of nkChckRange64: genRangeChck(p, n, r, "chckRange64")
  of nkChckRange: genRangeChck(p, n, r, "chckRange")
  of nkStringToCString: convStrToCStr(p, n, r)
  of nkCStringToString: convCStrToStr(p, n, r)
  of nkStmtListExpr: genStmtListExpr(p, n, r)
  of nkEmpty: nil
  of nkLambdaKinds: 
    let s = n.sons[namePos].sym
    discard mangleName(s)
    r.res = s.loc.r
    if lfNoDecl in s.loc.flags or s.magic != mNone or isGenericRoutine(s): nil
    elif not p.g.generatedSyms.containsOrIncl(s.id):
      var r2: TCompRes
      genProc(p, s, r2)
      app(r.com, mergeStmt(r2))
  of nkMetaNode: gen(p, n.sons[0], r)
  of nkType: r.res = genTypeInfo(p, n.typ)
  else: InternalError(n.info, "gen: unknown node type: " & $n.kind)
  
var globals: PGlobals

proc newModule(module: PSym, filename: string): BModule = 
  new(result)
  result.filename = filename
  result.module = module
  if globals == nil: globals = newGlobals()
  
proc genHeader(): PRope = 
  result = ropef("/* Generated by the Nimrod Compiler v$1 */$n" &
      "/*   (c) 2012 Andreas Rumpf */$n$n" & "$nvar Globals = this;$n" &
      "var framePtr = null;$n" & "var excHandler = null;$n", 
                 [toRope(versionAsString)])

proc genModule(p: var TProc, n: PNode, r: var TCompRes) = 
  genStmt(p, n, r)
  if optStackTrace in p.options: 
    r.com = ropef("var F = {procname:$1,prev:framePtr,filename:$2,line:0};$n" &
        "framePtr = F;$n" & "$3" & "framePtr = framePtr.prev;$n", [
        makeCString("module " & p.module.module.name.s), 
        makeCString(toFilename(p.module.module.info)), r.com])

proc myProcess(b: PPassContext, n: PNode): PNode = 
  if passes.skipCodegen(n): return n
  var 
    p: TProc
    r: TCompRes
  result = n
  var m = BModule(b)
  if m.module == nil: InternalError(n.info, "myProcess")
  initProc(p, globals, m, nil, m.module.options)
  genModule(p, n, r)
  app(p.g.code, p.data)
  app(p.g.code, mergeStmt(r))

proc myClose(b: PPassContext, n: PNode): PNode = 
  if passes.skipCodegen(n): return n
  result = myProcess(b, n)
  var m = BModule(b)
  if sfMainModule in m.module.flags:
    for prc in globals.forwarded:
      if not globals.generatedSyms.containsOrIncl(prc.id):
        var 
          p: TProc
          r: TCompRes
        initProc(p, globals, m, nil, m.module.options)
        genProc(p, prc, r)
        app(p.g.code, mergeStmt(r))
    
    var disp = generateMethodDispatchers()
    for i in 0..sonsLen(disp)-1: 
      let prc = disp.sons[i].sym
      if not globals.generatedSyms.containsOrIncl(prc.id):
        var 
          p: TProc
          r: TCompRes
        initProc(p, globals, m, nil, m.module.options)
        genProc(p, prc, r)
        app(p.g.code, mergeStmt(r))

    # write the file:
    var code = con(globals.typeInfo, globals.code)
    var outfile = changeFileExt(completeCFilePath(m.filename), "js")
    discard writeRopeIfNotEqual(con(genHeader(), code), outfile)

proc myOpenCached(s: PSym, filename: string, rd: PRodReader): PPassContext = 
  InternalError("symbol files are not possible with the Ecmas code generator")
  result = nil

proc myOpen(s: PSym, filename: string): PPassContext = 
  result = newModule(s, filename)

proc ecmasgenPass(): TPass = 
  InitPass(result)
  result.open = myOpen
  result.close = myClose
  result.openCached = myOpenCached
  result.process = myProcess
