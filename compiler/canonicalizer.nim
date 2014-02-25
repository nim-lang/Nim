#
#
#           The Nimrod Compiler
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the canonalization for the various caching mechanisms.

import strutils, db_sqlite, md5

var db: TDbConn

# We *hash* the relevant information into 128 bit hashes. This should be good enough
# to prevent any collisions.

type
  TUid = distinct MD5Digest

# For name mangling we encode these hashes via a variant of base64 (called
# 'base64a') and prepend the *primary* identifier to ease the debugging pain.
# So a signature like:
#
#   proc gABI(c: PCtx; n: PNode; opc: TOpcode; a, b: TRegister; imm: BiggestInt)
#
# is mangled into:
#   gABI_MTdmOWY5MTQ1MDcyNGQ3ZA
#
# This is a good compromise between correctness and brevity. ;-)

const
  cb64 = [
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
    "O", "P", "Q", "R", "S", "T" "U", "V", "W", "X", "Y", "Z", 
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", 
    "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", 
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "_A", "_B"]

proc toBase64a(s: cstring, len: int): string =
  ## encodes `s` into base64 representation. After `lineLen` characters, a 
  ## `newline` is added.
  var total = ((len + 2) div 3) * 4
  result = newStringOfCap(total)
  var i = 0
  while i < s.len - 2:
    let a = ord(s[i])
    let b = ord(s[i+1])
    let c = ord(s[i+2])
    result.add cb64[a shr 2]
    result.add cb64[((a and 3) shl 4) or ((b and 0xF0) shr 4)]
    result.add cb64[((b and 0x0F) shl 2) or ((c and 0xC0) shr 6)]
    result.add cb64[c and 0x3F]
    inc(i, 3)
  if i < s.len-1:
    let a = ord(s[i])
    let b = ord(s[i+1])
    result.add cb64[a shr 2]
    result.add cb64[((a and 3) shl 4) or ((b and 0xF0) shr 4)]
    result.add cb64[((b and 0x0F) shl 2)]
  elif i < s.len:
    let a = ord(s[i])
    result.add cb64[a shr 2]
    result.add cb64[(a and 3) shl 4]

proc toBase64a(u: TUid): string = toBase64a(cast[cstring](u), sizeof(u))

proc `&=`(c: var MD5Context, s: string) = md5Update(c, s, s.len)

proc hashSym(c: var MD5Context, s: PSym) =
  if sfAnon in s.flags or s.kind == skGenericParam:
    c &= ":anon"
  else:
    var it = s.owner
    while it != nil: 
      hashSym(c, it)
      c &= "."
      it = s.owner
    c &= s.name.s

proc hashTree(c: var MD5Context, n: PNode) =
  if n == nil:
    c &= "null"
    return
  var k = n.kind
  md5Update(c, cast[cstring](addr(k)), 1)
  # we really must not hash line information. 'n.typ' is debatable but
  # shouldn't be necessary for now and avoids potential infinite recursions.
  case n.kind
  of nkEmpty, nkNilLit, nkType: discard
  of nkIdent:
    c &= n.ident.s
  of nkSym:
    hashSym(c, n.sym)
  of nkCharLit..nkUInt64Lit:
    var v = n.intVal
    md5Update(c, cast[cstring](addr(v)), sizeof(v))
  of nkFloatLit..nkFloat64Lit:
    var v = n.floatVal
    md5Update(c, cast[cstring](addr(v)), sizeof(v))
  of nkStrLit..nkTripleStrLit:
    c &= n.strVal
  else:
    for i in 0.. <n.len: hashTree(c, n.sons[i])

const 
  typeToStr: array[TTypeKind, string] = ["None", "bool", "Char", "empty",
    "Array Constructor [$1]", "nil", "expr", "stmt", "typeDesc",
    "GenericInvokation", "GenericBody", "GenericInst", "GenericParam",
    "distinct $1", "enum", "ordinal[$1]", "array[$1, $2]", "object", "tuple",
    "set[$1]", "range[$1]", "ptr ", "ref ", "var ", "seq[$1]", "proc",
    "pointer", "OpenArray[$1]", "string", "CString", "Forward",
    "int", "int8", "int16", "int32", "int64",
    "float", "float32", "float64", "float128",
    "uint", "uint8", "uint16", "uint32", "uint64",
    "bignum", "const ",
    "!", "varargs[$1]", "iter[$1]", "Error Type",
    "BuiltInTypeClass", "UserTypeClass",
    "UserTypeClassInst", "CompositeTypeClass",
    "and", "or", "not", "any", "static", "TypeFromExpr", "FieldAccessor"]

proc typeToString(typ: PType, prefer: TPreferedDesc = preferName): string =
  var t = typ
  result = ""
  if t == nil: return 
  if prefer == preferName and t.sym != nil and sfAnon notin t.sym.flags:
    if t.kind == tyInt and isIntLit(t):
      return t.sym.name.s & " literal(" & $t.n.intVal & ")"
    return t.sym.name.s
  case t.kind
  of tyInt:
    if not isIntLit(t) or prefer == preferExported:
      result = typeToStr[t.kind]
    else:
      result = "int literal(" & $t.n.intVal & ")"
  of tyGenericBody, tyGenericInst, tyGenericInvokation:
    result = typeToString(t.sons[0]) & '['
    for i in countup(1, sonsLen(t) -1 -ord(t.kind != tyGenericInvokation)):
      if i > 1: add(result, ", ")
      add(result, typeToString(t.sons[i]))
    add(result, ']')
  of tyTypeDesc:
    if t.base.kind == tyNone: result = "typedesc"
    else: result = "typedesc[" & typeToString(t.base) & "]"
  of tyStatic:
    internalAssert t.len > 0
    result = "static[" & typeToString(t.sons[0]) & "]"
  of tyUserTypeClass:
    internalAssert t.sym != nil and t.sym.owner != nil
    return t.sym.owner.name.s
  of tyBuiltInTypeClass:
    result = case t.base.kind:
      of tyVar: "var"
      of tyRef: "ref"
      of tyPtr: "ptr"
      of tySequence: "seq"
      of tyArray: "array"
      of tySet: "set"
      of tyRange: "range"
      of tyDistinct: "distinct"
      of tyProc: "proc"
      of tyObject: "object"
      of tyTuple: "tuple"
      else: (internalAssert(false); "")
  of tyUserTypeClassInst:
    let body = t.base
    result = body.sym.name.s & "["
    for i in countup(1, sonsLen(t) - 2):
      if i > 1: add(result, ", ")
      add(result, typeToString(t.sons[i]))
    result.add "]"
  of tyAnd:
    result = typeToString(t.sons[0]) & " and " & typeToString(t.sons[1])
  of tyOr:
    result = typeToString(t.sons[0]) & " or " & typeToString(t.sons[1])
  of tyNot:
    result = "not " & typeToString(t.sons[0])
  of tyExpr:
    internalAssert t.len == 0
    result = "expr"
  of tyFromExpr, tyFieldAccessor:
    result = renderTree(t.n)
  of tyArray: 
    if t.sons[0].kind == tyRange: 
      result = "array[" & hashTree(t.sons[0].n) & ", " &
          typeToString(t.sons[1]) & ']'
    else: 
      result = "array[" & typeToString(t.sons[0]) & ", " &
          typeToString(t.sons[1]) & ']'
  of tyArrayConstr: 
    result = "Array constructor[" & hashTree(t.sons[0].n) & ", " &
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
  of tyPtr, tyRef, tyVar, tyMutable, tyConst: 
    result = typeToStr[t.kind] & typeToString(t.sons[0])
  of tyRange:
    result = "range " & hashTree(t.n)
    if prefer != preferExported:
      result.add("(" & typeToString(t.sons[0]) & ")")
  of tyProc:
    result = if tfIterator in t.flags: "iterator (" else: "proc ("
    for i in countup(1, sonsLen(t) - 1): 
      add(result, typeToString(t.sons[i]))
      if i < sonsLen(t) - 1: add(result, ", ")
    add(result, ')')
    if t.sons[0] != nil: add(result, ": " & typeToString(t.sons[0]))
    var prag: string
    if t.callConv != ccDefault: prag = CallingConvToStr[t.callConv]
    else: prag = ""
    if tfNoSideEffect in t.flags: 
      addSep(prag)
      add(prag, "noSideEffect")
    if tfThread in t.flags:
      addSep(prag)
      add(prag, "thread")
    if len(prag) != 0: add(result, "{." & prag & ".}")
  of tyVarargs, tyIter:
    result = typeToStr[t.kind] % typeToString(t.sons[0])
  else: 
    result = typeToStr[t.kind]
  if tfShared in t.flags: result = "shared " & result
  if tfNotNil in t.flags: result.add(" not nil")


proc createDb() =
  db.exec(sql"""
    create table if not exists Module(
      id integer primary key,
      name varchar(256) not null,
      fullpath varchar(256) not null,
      interfHash varchar(256) not null,
      fullHash varchar(256) not null,
      
      created timestamp not null default (DATETIME('now')),
    );""")

  db.exec(sql"""
    create table if not exists Symbol(
      id integer primary key,
      module integer not null,
      name varchar(max) not null,
      data varchar(max) not null,
      created timestamp not null default (DATETIME('now')),

      foreign key (module) references module(id)
    );""")
    
  db.exec(sql"""
    create table if not exists Type(
      id integer primary key,
      module integer not null,
      name varchar(max) not null,
      data varchar(max) not null,
      created timestamp not null default (DATETIME('now')),

      foreign key (module) references module(id)
    );""")


  #db.exec(sql"""
  #  --create unique index if not exists TsstNameIx on TestResult(name);
  #  """, [])

