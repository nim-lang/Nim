#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Algorithms for the abstract syntax tree: hash tables, lists
# and sets of nodes are supported. Efficiency is important as
# the data structures here are used in various places of the compiler.

import 
  ast, nhashes, strutils, options, msgs, ropes, idents

proc hashNode*(p: PObject): THash
proc treeToYaml*(n: PNode, indent: int = 0, maxRecDepth: int = - 1): PRope
  # Convert a tree into its YAML representation; this is used by the
  # YAML code generator and it is invaluable for debugging purposes.
  # If maxRecDepht <> -1 then it won't print the whole graph.
proc typeToYaml*(n: PType, indent: int = 0, maxRecDepth: int = - 1): PRope
proc symToYaml*(n: PSym, indent: int = 0, maxRecDepth: int = - 1): PRope
proc lineInfoToStr*(info: TLineInfo): PRope
  
# ----------------------- node sets: ---------------------------------------
proc ObjectSetContains*(t: TObjectSet, obj: PObject): bool
  # returns true whether n is in t
proc ObjectSetIncl*(t: var TObjectSet, obj: PObject)
  # include an element n in the table t
proc ObjectSetContainsOrIncl*(t: var TObjectSet, obj: PObject): bool
  # more are not needed ...

# ----------------------- (key, val)-Hashtables ----------------------------
proc TablePut*(t: var TTable, key, val: PObject)
proc TableGet*(t: TTable, key: PObject): PObject
type 
  TCmpProc* = proc (key, closure: PObject): bool # should return true if found

proc TableSearch*(t: TTable, key, closure: PObject, comparator: TCmpProc): PObject
  # return val as soon as comparator returns true; if this never happens,
  # nil is returned

# ----------------------- str table -----------------------------------------
proc StrTableContains*(t: TStrTable, n: PSym): bool
proc StrTableAdd*(t: var TStrTable, n: PSym)
proc StrTableGet*(t: TStrTable, name: PIdent): PSym
proc StrTableIncl*(t: var TStrTable, n: PSym): bool
  # returns true if n is already in the string table
  # the iterator scheme:
type 
  TTabIter*{.final.} = object # consider all fields here private
    h*: THash                 # current hash
  

proc InitTabIter*(ti: var TTabIter, tab: TStrTable): PSym
proc NextIter*(ti: var TTabIter, tab: TStrTable): PSym
  # usage:
  # var i: TTabIter; s: PSym;
  # s := InitTabIter(i, table);
  # while s <> nil do begin
  #   ...
  #   s := NextIter(i, table);
  # end;
type 
  TIdentIter*{.final.} = object # iterator over all syms with the same identifier
    h*: THash                 # current hash
    name*: PIdent


proc InitIdentIter*(ti: var TIdentIter, tab: TStrTable, s: PIdent): PSym
proc NextIdentIter*(ti: var TIdentIter, tab: TStrTable): PSym

# -------------- symbol table ----------------------------------------------
# Each TParser object (which represents a module being compiled) has its own
# symbol table. A symbol table is organized as a stack of str tables. The
# stack represents the different scopes.
# Stack pointer:
# 0                imported symbols from other modules
# 1                module level
# 2                proc level
# 3                nested statements
# ...
#
type 
  TSymTab*{.final.} = object 
    tos*: Natural             # top of stack
    stack*: seq[TStrTable]


proc InitSymTab*(tab: var TSymTab)
proc DeinitSymTab*(tab: var TSymTab)
proc SymTabGet*(tab: TSymTab, s: PIdent): PSym
proc SymTabLocalGet*(tab: TSymTab, s: PIdent): PSym
proc SymTabAdd*(tab: var TSymTab, e: PSym)
proc SymTabAddAt*(tab: var TSymTab, e: PSym, at: Natural)
proc SymTabAddUnique*(tab: var TSymTab, e: PSym): TResult
proc SymTabAddUniqueAt*(tab: var TSymTab, e: PSym, at: Natural): TResult
proc OpenScope*(tab: var TSymTab)
proc RawCloseScope*(tab: var TSymTab)
  # the real "closeScope" adds some
  # checks in parsobj
  # these are for debugging only:
proc debug*(n: PSym)
proc debug*(n: PType)
proc debug*(n: PNode)

# --------------------------- ident tables ----------------------------------
proc IdTableGet*(t: TIdTable, key: PIdObj): PObject
proc IdTableGet*(t: TIdTable, key: int): PObject
proc IdTablePut*(t: var TIdTable, key: PIdObj, val: PObject)
proc IdTableHasObjectAsKey*(t: TIdTable, key: PIdObj): bool
  # checks if `t` contains the `key` (compared by the pointer value, not only
  # `key`'s id)
proc IdNodeTableGet*(t: TIdNodeTable, key: PIdObj): PNode
proc IdNodeTablePut*(t: var TIdNodeTable, key: PIdObj, val: PNode)
proc writeIdNodeTable*(t: TIdNodeTable)

# ---------------------------------------------------------------------------

proc getSymFromList*(list: PNode, ident: PIdent, start: int = 0): PSym
proc lookupInRecord*(n: PNode, field: PIdent): PSym
proc getModule*(s: PSym): PSym
proc mustRehash*(length, counter: int): bool
proc nextTry*(h, maxHash: THash): THash

# ------------- table[int, int] ---------------------------------------------
const 
  InvalidKey* = low(int)

type 
  TIIPair*{.final.} = object 
    key*, val*: int

  TIIPairSeq* = seq[TIIPair]
  TIITable*{.final.} = object # table[int, int]
    counter*: int
    data*: TIIPairSeq


proc initIITable*(x: var TIITable)
proc IITableGet*(t: TIITable, key: int): int
proc IITablePut*(t: var TIITable, key, val: int)

# implementation

proc lookupInRecord(n: PNode, field: PIdent): PSym = 
  result = nil
  case n.kind
  of nkRecList: 
    for i in countup(0, sonsLen(n) - 1): 
      result = lookupInRecord(n.sons[i], field)
      if result != nil: return 
  of nkRecCase: 
    if (n.sons[0].kind != nkSym): InternalError(n.info, "lookupInRecord")
    result = lookupInRecord(n.sons[0], field)
    if result != nil: return 
    for i in countup(1, sonsLen(n) - 1): 
      case n.sons[i].kind
      of nkOfBranch, nkElse: 
        result = lookupInRecord(lastSon(n.sons[i]), field)
        if result != nil: return 
      else: internalError(n.info, "lookupInRecord(record case branch)")
  of nkSym: 
    if n.sym.name.id == field.id: result = n.sym
  else: internalError(n.info, "lookupInRecord()")
  
proc getModule(s: PSym): PSym = 
  result = s
  assert((result.kind == skModule) or (result.owner != result))
  while (result != nil) and (result.kind != skModule): result = result.owner
  
proc getSymFromList(list: PNode, ident: PIdent, start: int = 0): PSym = 
  for i in countup(start, sonsLen(list) - 1): 
    if list.sons[i].kind != nkSym: InternalError(list.info, "getSymFromList")
    result = list.sons[i].sym
    if result.name.id == ident.id: return 
  result = nil

proc hashNode(p: PObject): THash = 
  result = hashPtr(cast[pointer](p))

proc mustRehash(length, counter: int): bool = 
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

proc spaces(x: int): PRope = 
  # returns x spaces
  result = toRope(repeatChar(x))

proc toYamlChar(c: Char): string = 
  case c
  of '\0'..'\x1F', '\x80'..'\xFF': result = "\\u" & strutils.toHex(ord(c), 4)
  of '\'', '\"', '\\': result = '\\' & c
  else: result = c & ""
  
proc makeYamlString(s: string): PRope = 
  # We have to split long strings into many ropes. Otherwise
  # this could trigger InternalError(111). See the ropes module for
  # further information.
  const 
    MaxLineLength = 64
  var res: string
  result = nil
  res = "\""
  for i in countup(0, len(s) + 0 - 1): 
    if (i - 0 + 1) mod MaxLineLength == 0: 
      add(res, '\"')
      add(res, "\n")
      app(result, toRope(res))
      res = "\""              # reset
    add(res, toYamlChar(s[i]))
  add(res, '\"')
  app(result, toRope(res))

proc flagsToStr[T](flags: set[T]): PRope = 
  if flags == {}: 
    result = toRope("[]")
  else: 
    result = nil
    for x in items(flags): 
      if result != nil: app(result, ", ")
      app(result, makeYamlString($x))
    result = con("[", con(result, "]"))

proc lineInfoToStr(info: TLineInfo): PRope = 
  result = ropef("[$1, $2, $3]", [makeYamlString(toFilename(info)), 
                                  toRope(toLinenumber(info)), 
                                  toRope(toColumn(info))])

proc treeToYamlAux(n: PNode, marker: var TIntSet, indent, maxRecDepth: int): PRope
proc symToYamlAux(n: PSym, marker: var TIntSet, indent, maxRecDepth: int): PRope
proc typeToYamlAux(n: PType, marker: var TIntSet, indent, maxRecDepth: int): PRope
proc strTableToYaml(n: TStrTable, marker: var TIntSet, indent: int, 
                    maxRecDepth: int): PRope = 
  var 
    istr: PRope
    mycount: int
  istr = spaces(indent + 2)
  result = toRope("[")
  mycount = 0
  for i in countup(0, high(n.data)): 
    if n.data[i] != nil: 
      if mycount > 0: app(result, ",")
      appf(result, "$n$1$2", 
           [istr, symToYamlAux(n.data[i], marker, indent + 2, maxRecDepth - 1)])
      inc(mycount)
  if mycount > 0: appf(result, "$n$1", [spaces(indent)])
  app(result, "]")
  assert(mycount == n.counter)

proc ropeConstr(indent: int, c: openarray[PRope]): PRope = 
  # array of (name, value) pairs
  var 
    istr: PRope
    i: int
  istr = spaces(indent + 2)
  result = toRope("{")
  i = 0
  while i <= high(c): 
    if i > 0: app(result, ",")
    appf(result, "$n$1\"$2\": $3", [istr, c[i], c[i + 1]])
    inc(i, 2)
  appf(result, "$n$1}", [spaces(indent)])

proc symToYamlAux(n: PSym, marker: var TIntSet, indent: int, 
                  maxRecDepth: int): PRope = 
  if n == nil: 
    result = toRope("null")
  elif IntSetContainsOrIncl(marker, n.id): 
    result = ropef("\"$1 @$2\"", [toRope(n.name.s), toRope(
        strutils.toHex(cast[TAddress](n), sizeof(n) * 2))])
  else: 
    var ast = treeToYamlAux(n.ast, marker, indent + 2, maxRecDepth - 1)
    result = ropeConstr(indent, [toRope("kind"), 
                                 makeYamlString($n.kind), 
                                 toRope("name"), makeYamlString(n.name.s), 
                                 toRope("typ"), typeToYamlAux(n.typ, marker, 
                                   indent + 2, maxRecDepth - 1), 
                                 toRope("info"), lineInfoToStr(n.info), 
                                 toRope("flags"), flagsToStr(n.flags), 
                                 toRope("magic"), makeYamlString($n.magic), 
                                 toRope("ast"), ast, toRope("options"), 
                                 flagsToStr(n.options), toRope("position"), 
                                 toRope(n.position)])

proc typeToYamlAux(n: PType, marker: var TIntSet, indent: int, 
                   maxRecDepth: int): PRope = 
  if n == nil: 
    result = toRope("null")
  elif intSetContainsOrIncl(marker, n.id): 
    result = ropef("\"$1 @$2\"", [toRope($n.kind), toRope(
        strutils.toHex(cast[TAddress](n), sizeof(n) * 2))])
  else: 
    if sonsLen(n) > 0: 
      result = toRope("[")
      for i in countup(0, sonsLen(n) - 1): 
        if i > 0: app(result, ",")
        appf(result, "$n$1$2", [spaces(indent + 4), typeToYamlAux(n.sons[i], 
            marker, indent + 4, maxRecDepth - 1)])
      appf(result, "$n$1]", [spaces(indent + 2)])
    else: 
      result = toRope("null")
    result = ropeConstr(indent, [toRope("kind"), 
                                 makeYamlString($n.kind), 
                                 toRope("sym"), symToYamlAux(n.sym, marker, 
        indent + 2, maxRecDepth - 1), toRope("n"), treeToYamlAux(n.n, marker, 
        indent + 2, maxRecDepth - 1), toRope("flags"), FlagsToStr(n.flags), 
                                 toRope("callconv"), 
                                 makeYamlString(CallingConvToStr[n.callConv]), 
                                 toRope("size"), toRope(n.size), 
                                 toRope("align"), toRope(n.align), 
                                 toRope("sons"), result])

proc treeToYamlAux(n: PNode, marker: var TIntSet, indent: int, 
                   maxRecDepth: int): PRope = 
  var istr: PRope
  if n == nil: 
    result = toRope("null")
  else: 
    istr = spaces(indent + 2)
    result = ropef("{$n$1\"kind\": $2", 
                   [istr, makeYamlString($n.kind)])
    if maxRecDepth != 0: 
      appf(result, ",$n$1\"info\": $2", [istr, lineInfoToStr(n.info)])
      case n.kind
      of nkCharLit..nkInt64Lit: 
        appf(result, ",$n$1\"intVal\": $2", [istr, toRope(n.intVal)])
      of nkFloatLit, nkFloat32Lit, nkFloat64Lit: 
        appf(result, ",$n$1\"floatVal\": $2", [istr, toRopeF(n.floatVal)])
      of nkStrLit..nkTripleStrLit: 
        appf(result, ",$n$1\"strVal\": $2", [istr, makeYamlString(n.strVal)])
      of nkSym: 
        appf(result, ",$n$1\"sym\": $2", 
             [istr, symToYamlAux(n.sym, marker, indent + 2, maxRecDepth)])
      of nkIdent: 
        if n.ident != nil: 
          appf(result, ",$n$1\"ident\": $2", [istr, makeYamlString(n.ident.s)])
        else: 
          appf(result, ",$n$1\"ident\": null", [istr])
      else: 
        if sonsLen(n) > 0: 
          appf(result, ",$n$1\"sons\": [", [istr])
          for i in countup(0, sonsLen(n) - 1): 
            if i > 0: app(result, ",")
            appf(result, "$n$1$2", [spaces(indent + 4), treeToYamlAux(n.sons[i], 
                marker, indent + 4, maxRecDepth - 1)])
          appf(result, "$n$1]", [istr])
      appf(result, ",$n$1\"typ\": $2", 
           [istr, typeToYamlAux(n.typ, marker, indent + 2, maxRecDepth)])
    appf(result, "$n$1}", [spaces(indent)])

proc treeToYaml(n: PNode, indent: int = 0, maxRecDepth: int = - 1): PRope = 
  var marker: TIntSet
  IntSetInit(marker)
  result = treeToYamlAux(n, marker, indent, maxRecDepth)

proc typeToYaml(n: PType, indent: int = 0, maxRecDepth: int = - 1): PRope = 
  var marker: TIntSet
  IntSetInit(marker)
  result = typeToYamlAux(n, marker, indent, maxRecDepth)

proc symToYaml(n: PSym, indent: int = 0, maxRecDepth: int = - 1): PRope = 
  var marker: TIntSet
  IntSetInit(marker)
  result = symToYamlAux(n, marker, indent, maxRecDepth)

proc debugType(n: PType): PRope = 
  if n == nil: 
    result = toRope("null")
  else: 
    result = toRope($n.kind)
    if n.sym != nil: 
      app(result, " ")
      app(result, n.sym.name.s)
    if (n.kind != tyString) and (sonsLen(n) > 0): 
      app(result, "(")
      for i in countup(0, sonsLen(n) - 1): 
        if i > 0: app(result, ", ")
        if n.sons[i] == nil: 
          app(result, "null")
        else: 
          app(result, debugType(n.sons[i])) 
      app(result, ")")

proc debugTree(n: PNode, indent: int, maxRecDepth: int): PRope = 
  var istr: PRope
  if n == nil: 
    result = toRope("null")
  else: 
    istr = spaces(indent + 2)
    result = ropef("{$n$1\"kind\": $2", 
                   [istr, makeYamlString($n.kind)])
    if maxRecDepth != 0: 
      case n.kind
      of nkCharLit..nkInt64Lit: 
        appf(result, ",$n$1\"intVal\": $2", [istr, toRope(n.intVal)])
      of nkFloatLit, nkFloat32Lit, nkFloat64Lit: 
        appf(result, ",$n$1\"floatVal\": $2", [istr, toRopeF(n.floatVal)])
      of nkStrLit..nkTripleStrLit: 
        appf(result, ",$n$1\"strVal\": $2", [istr, makeYamlString(n.strVal)])
      of nkSym: 
        appf(result, ",$n$1\"sym\": $2_$3", 
             [istr, toRope(n.sym.name.s), toRope(n.sym.id)])
      of nkIdent: 
        if n.ident != nil: 
          appf(result, ",$n$1\"ident\": $2", [istr, makeYamlString(n.ident.s)])
        else: 
          appf(result, ",$n$1\"ident\": null", [istr])
      else: 
        if sonsLen(n) > 0: 
          appf(result, ",$n$1\"sons\": [", [istr])
          for i in countup(0, sonsLen(n) - 1): 
            if i > 0: app(result, ",")
            appf(result, "$n$1$2", [spaces(indent + 4), debugTree(n.sons[i], 
                indent + 4, maxRecDepth - 1)])
          appf(result, "$n$1]", [istr])
    appf(result, "$n$1}", [spaces(indent)])

proc debug(n: PSym) = 
  #writeln(stdout, ropeToStr(symToYaml(n, 0, 1)))
  writeln(stdout, ropeToStr(ropef("$1_$2: $3, $4", [
    toRope(n.name.s), toRope(n.id), flagsToStr(n.flags), 
    flagsToStr(n.loc.flags)])))

proc debug(n: PType) = 
  writeln(stdout, ropeToStr(debugType(n)))

proc debug(n: PNode) = 
  writeln(stdout, ropeToStr(debugTree(n, 0, 100)))

const 
  EmptySeq = @ []

proc nextTry(h, maxHash: THash): THash = 
  result = ((5 * h) + 1) and maxHash # For any initial h in range(maxHash), repeating that maxHash times
                                     # generates each int in range(maxHash) exactly once (see any text on
                                     # random-number generation for proof).
  
proc objectSetContains(t: TObjectSet, obj: PObject): bool = 
  # returns true whether n is in t
  var h: THash
  h = hashNode(obj) and high(t.data) # start with real hash value
  while t.data[h] != nil: 
    if (t.data[h] == obj): 
      return true
    h = nextTry(h, high(t.data))
  result = false

proc objectSetRawInsert(data: var TObjectSeq, obj: PObject) = 
  var h: THash
  h = HashNode(obj) and high(data)
  while data[h] != nil: 
    assert(data[h] != obj)
    h = nextTry(h, high(data))
  assert(data[h] == nil)
  data[h] = obj

proc objectSetEnlarge(t: var TObjectSet) = 
  var n: TObjectSeq
  newSeq(n, len(t.data) * growthFactor)
  for i in countup(0, high(t.data)): 
    if t.data[i] != nil: objectSetRawInsert(n, t.data[i])
  swap(t.data, n)

proc objectSetIncl(t: var TObjectSet, obj: PObject) = 
  if mustRehash(len(t.data), t.counter): objectSetEnlarge(t)
  objectSetRawInsert(t.data, obj)
  inc(t.counter)

proc objectSetContainsOrIncl(t: var TObjectSet, obj: PObject): bool = 
  # returns true if obj is already in the string table:
  var 
    h: THash
    it: PObject
  h = HashNode(obj) and high(t.data)
  while true: 
    it = t.data[h]
    if it == nil: break 
    if it == obj: 
      return true             # found it
    h = nextTry(h, high(t.data))
  if mustRehash(len(t.data), t.counter): 
    objectSetEnlarge(t)
    objectSetRawInsert(t.data, obj)
  else: 
    assert(t.data[h] == nil)
    t.data[h] = obj
  inc(t.counter)
  result = false

proc TableRawGet(t: TTable, key: PObject): int = 
  var h: THash
  h = hashNode(key) and high(t.data) # start with real hash value
  while t.data[h].key != nil: 
    if (t.data[h].key == key): 
      return h
    h = nextTry(h, high(t.data))
  result = - 1

proc TableSearch(t: TTable, key, closure: PObject, comparator: TCmpProc): PObject = 
  var h: THash
  h = hashNode(key) and high(t.data) # start with real hash value
  while t.data[h].key != nil: 
    if (t.data[h].key == key): 
      if comparator(t.data[h].val, closure): 
        # BUGFIX 1
        return t.data[h].val
    h = nextTry(h, high(t.data))
  result = nil

proc TableGet(t: TTable, key: PObject): PObject = 
  var index: int
  index = TableRawGet(t, key)
  if index >= 0: result = t.data[index].val
  else: result = nil
  
proc TableRawInsert(data: var TPairSeq, key, val: PObject) = 
  var h: THash
  h = HashNode(key) and high(data)
  while data[h].key != nil: 
    assert(data[h].key != key)
    h = nextTry(h, high(data))
  assert(data[h].key == nil)
  data[h].key = key
  data[h].val = val

proc TableEnlarge(t: var TTable) = 
  var n: TPairSeq
  newSeq(n, len(t.data) * growthFactor)
  for i in countup(0, high(t.data)): 
    if t.data[i].key != nil: TableRawInsert(n, t.data[i].key, t.data[i].val)
  swap(t.data, n)

proc TablePut(t: var TTable, key, val: PObject) = 
  var index: int
  index = TableRawGet(t, key)
  if index >= 0: 
    t.data[index].val = val
  else: 
    if mustRehash(len(t.data), t.counter): TableEnlarge(t)
    TableRawInsert(t.data, key, val)
    inc(t.counter)

proc StrTableContains(t: TStrTable, n: PSym): bool = 
  var h: THash
  h = n.name.h and high(t.data) # start with real hash value
  while t.data[h] != nil: 
    if (t.data[h] == n): 
      return true
    h = nextTry(h, high(t.data))
  result = false

proc StrTableRawInsert(data: var TSymSeq, n: PSym) = 
  var h: THash
  h = n.name.h and high(data)
  while data[h] != nil: 
    if data[h] == n: InternalError(n.info, "StrTableRawInsert: " & n.name.s)
    h = nextTry(h, high(data))
  assert(data[h] == nil)
  data[h] = n

proc StrTableEnlarge(t: var TStrTable) = 
  var n: TSymSeq
  newSeq(n, len(t.data) * growthFactor)
  for i in countup(0, high(t.data)): 
    if t.data[i] != nil: StrTableRawInsert(n, t.data[i])
  swap(t.data, n)

proc StrTableAdd(t: var TStrTable, n: PSym) = 
  if mustRehash(len(t.data), t.counter): StrTableEnlarge(t)
  StrTableRawInsert(t.data, n)
  inc(t.counter)

proc StrTableIncl(t: var TStrTable, n: PSym): bool = 
  # returns true if n is already in the string table:
  var 
    h: THash
    it: PSym
  h = n.name.h and high(t.data)
  while true: 
    it = t.data[h]
    if it == nil: break 
    if it.name.id == n.name.id: 
      return true             # found it
    h = nextTry(h, high(t.data))
  if mustRehash(len(t.data), t.counter): 
    StrTableEnlarge(t)
    StrTableRawInsert(t.data, n)
  else: 
    assert(t.data[h] == nil)
    t.data[h] = n
  inc(t.counter)
  result = false

proc StrTableGet(t: TStrTable, name: PIdent): PSym = 
  var h: THash
  h = name.h and high(t.data)
  while true: 
    result = t.data[h]
    if result == nil: break 
    if result.name.id == name.id: break 
    h = nextTry(h, high(t.data))

proc InitIdentIter(ti: var TIdentIter, tab: TStrTable, s: PIdent): PSym = 
  ti.h = s.h
  ti.name = s
  if tab.Counter == 0: result = nil
  else: result = NextIdentIter(ti, tab)
  
proc NextIdentIter(ti: var TIdentIter, tab: TStrTable): PSym = 
  var h, start: THash
  h = ti.h and high(tab.data)
  start = h
  result = tab.data[h]
  while (result != nil): 
    if result.Name.id == ti.name.id: break 
    h = nextTry(h, high(tab.data))
    if h == start: 
      result = nil
      break 
    result = tab.data[h]
  ti.h = nextTry(h, high(tab.data))

proc InitTabIter(ti: var TTabIter, tab: TStrTable): PSym = 
  ti.h = 0                    # we start by zero ...
  if tab.counter == 0: 
    result = nil              # FIX 1: removed endless loop
  else: 
    result = NextIter(ti, tab)
  
proc NextIter(ti: var TTabIter, tab: TStrTable): PSym = 
  result = nil
  while (ti.h <= high(tab.data)): 
    result = tab.data[ti.h]
    Inc(ti.h)                 # ... and increment by one always
    if result != nil: break 
  
proc InitSymTab(tab: var TSymTab) = 
  tab.tos = 0
  tab.stack = EmptySeq

proc DeinitSymTab(tab: var TSymTab) = 
  tab.stack = nil

proc SymTabLocalGet(tab: TSymTab, s: PIdent): PSym = 
  result = StrTableGet(tab.stack[tab.tos - 1], s)

proc SymTabGet(tab: TSymTab, s: PIdent): PSym = 
  for i in countdown(tab.tos - 1, 0): 
    result = StrTableGet(tab.stack[i], s)
    if result != nil: return 
  result = nil

proc SymTabAddAt(tab: var TSymTab, e: PSym, at: Natural) = 
  StrTableAdd(tab.stack[at], e)

proc SymTabAdd(tab: var TSymTab, e: PSym) = 
  StrTableAdd(tab.stack[tab.tos - 1], e)

proc SymTabAddUniqueAt(tab: var TSymTab, e: PSym, at: Natural): TResult = 
  if StrTableGet(tab.stack[at], e.name) != nil: 
    result = Failure
  else: 
    StrTableAdd(tab.stack[at], e)
    result = Success

proc SymTabAddUnique(tab: var TSymTab, e: PSym): TResult = 
  result = SymTabAddUniqueAt(tab, e, tab.tos - 1)

proc OpenScope(tab: var TSymTab) = 
  if tab.tos >= len(tab.stack): setlen(tab.stack, tab.tos + 1)
  initStrTable(tab.stack[tab.tos])
  Inc(tab.tos)

proc RawCloseScope(tab: var TSymTab) = 
  Dec(tab.tos)                #tab.stack[tab.tos] := nil;
  
proc hasEmptySlot(data: TIdPairSeq): bool = 
  for h in countup(0, high(data)): 
    if data[h].key == nil: 
      return true
  result = false

proc IdTableRawGet(t: TIdTable, key: int): int = 
  var h: THash
  h = key and high(t.data)    # start with real hash value
  while t.data[h].key != nil: 
    if (t.data[h].key.id == key): 
      return h
    h = nextTry(h, high(t.data))
  result = - 1

proc IdTableHasObjectAsKey(t: TIdTable, key: PIdObj): bool = 
  var index: int
  index = IdTableRawGet(t, key.id)
  if index >= 0: result = t.data[index].key == key
  else: result = false
  
proc IdTableGet(t: TIdTable, key: PIdObj): PObject = 
  var index: int
  index = IdTableRawGet(t, key.id)
  if index >= 0: result = t.data[index].val
  else: result = nil
  
proc IdTableGet(t: TIdTable, key: int): PObject = 
  var index: int
  index = IdTableRawGet(t, key)
  if index >= 0: result = t.data[index].val
  else: result = nil
  
proc IdTableRawInsert(data: var TIdPairSeq, key: PIdObj, val: PObject) = 
  var h: THash
  h = key.id and high(data)
  while data[h].key != nil: 
    assert(data[h].key.id != key.id)
    h = nextTry(h, high(data))
  assert(data[h].key == nil)
  data[h].key = key
  data[h].val = val

proc IdTablePut(t: var TIdTable, key: PIdObj, val: PObject) = 
  var 
    index: int
    n: TIdPairSeq
  index = IdTableRawGet(t, key.id)
  if index >= 0: 
    assert(t.data[index].key != nil)
    t.data[index].val = val
  else: 
    if mustRehash(len(t.data), t.counter): 
      newSeq(n, len(t.data) * growthFactor)
      for i in countup(0, high(t.data)): 
        if t.data[i].key != nil: 
          IdTableRawInsert(n, t.data[i].key, t.data[i].val)
      assert(hasEmptySlot(n))
      swap(t.data, n)
    IdTableRawInsert(t.data, key, val)
    inc(t.counter)

proc writeIdNodeTable(t: TIdNodeTable) = 
  nil

proc IdNodeTableRawGet(t: TIdNodeTable, key: PIdObj): int = 
  var h: THash
  h = key.id and high(t.data) # start with real hash value
  while t.data[h].key != nil: 
    if (t.data[h].key.id == key.id): 
      return h
    h = nextTry(h, high(t.data))
  result = - 1

proc IdNodeTableGet(t: TIdNodeTable, key: PIdObj): PNode = 
  var index: int
  index = IdNodeTableRawGet(t, key)
  if index >= 0: result = t.data[index].val
  else: result = nil
  
proc IdNodeTableRawInsert(data: var TIdNodePairSeq, key: PIdObj, val: PNode) = 
  var h: THash
  h = key.id and high(data)
  while data[h].key != nil: 
    assert(data[h].key.id != key.id)
    h = nextTry(h, high(data))
  assert(data[h].key == nil)
  data[h].key = key
  data[h].val = val

proc IdNodeTablePut(t: var TIdNodeTable, key: PIdObj, val: PNode) = 
  var index = IdNodeTableRawGet(t, key)
  if index >= 0: 
    assert(t.data[index].key != nil)
    t.data[index].val = val
  else: 
    if mustRehash(len(t.data), t.counter): 
      var n: TIdNodePairSeq
      newSeq(n, len(t.data) * growthFactor)
      for i in countup(0, high(t.data)): 
        if t.data[i].key != nil: 
          IdNodeTableRawInsert(n, t.data[i].key, t.data[i].val)
      swap(t.data, n)
    IdNodeTableRawInsert(t.data, key, val)
    inc(t.counter)

proc initIITable(x: var TIITable) = 
  x.counter = 0
  newSeq(x.data, startSize)
  for i in countup(0, startSize - 1): x.data[i].key = InvalidKey
  
proc IITableRawGet(t: TIITable, key: int): int = 
  var h: THash
  h = key and high(t.data)    # start with real hash value
  while t.data[h].key != InvalidKey: 
    if (t.data[h].key == key): 
      return h
    h = nextTry(h, high(t.data))
  result = - 1

proc IITableGet(t: TIITable, key: int): int = 
  var index: int
  index = IITableRawGet(t, key)
  if index >= 0: result = t.data[index].val
  else: result = InvalidKey
  
proc IITableRawInsert(data: var TIIPairSeq, key, val: int) = 
  var h: THash
  h = key and high(data)
  while data[h].key != InvalidKey: 
    assert(data[h].key != key)
    h = nextTry(h, high(data))
  assert(data[h].key == InvalidKey)
  data[h].key = key
  data[h].val = val

proc IITablePut(t: var TIITable, key, val: int) = 
  var 
    index: int
    n: TIIPairSeq
  index = IITableRawGet(t, key)
  if index >= 0: 
    assert(t.data[index].key != InvalidKey)
    t.data[index].val = val
  else: 
    if mustRehash(len(t.data), t.counter): 
      newSeq(n, len(t.data) * growthFactor)
      for i in countup(0, high(n)): n[i].key = InvalidKey
      for i in countup(0, high(t.data)): 
        if t.data[i].key != InvalidKey: 
          IITableRawInsert(n, t.data[i].key, t.data[i].val)
      swap(t.data, n)
    IITableRawInsert(t.data, key, val)
    inc(t.counter)
