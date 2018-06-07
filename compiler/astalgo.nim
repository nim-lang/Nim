#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Algorithms for the abstract syntax tree: hash tables, lists
# and sets of nodes are supported. Efficiency is important as
# the data structures here are used in various places of the compiler.

import
  ast, hashes, intsets, strutils, options, lineinfos, ropes, idents, rodutils,
  msgs

proc hashNode*(p: RootRef): Hash
proc treeToYaml*(conf: ConfigRef; n: PNode, indent: int = 0, maxRecDepth: int = - 1): Rope
  # Convert a tree into its YAML representation; this is used by the
  # YAML code generator and it is invaluable for debugging purposes.
  # If maxRecDepht <> -1 then it won't print the whole graph.
proc typeToYaml*(conf: ConfigRef; n: PType, indent: int = 0, maxRecDepth: int = - 1): Rope
proc symToYaml*(conf: ConfigRef; n: PSym, indent: int = 0, maxRecDepth: int = - 1): Rope
proc lineInfoToStr*(conf: ConfigRef; info: TLineInfo): Rope

when declared(echo):
  # these are for debugging only: They are not really deprecated, but I want
  # the warning so that release versions do not contain debugging statements:
  proc debug*(conf: ConfigRef; n: PSym) {.deprecated.}
  proc debug*(conf: ConfigRef; n: PType) {.deprecated.}
  proc debug*(conf: ConfigRef; n: PNode) {.deprecated.}

template mdbg*: bool {.dirty.} =
  when compiles(c.module):
    c.module.fileIdx == c.config.projectMainIdx
  elif compiles(c.c.module):
    c.c.module.fileIdx == c.c.config.projectMainIdx
  elif compiles(m.c.module):
    m.c.module.fileIdx == m.c.config.projectMainIdx
  elif compiles(cl.c.module):
    cl.c.module.fileIdx == cl.c.config.projectMainIdx
  elif compiles(p):
    when compiles(p.lex):
      p.lex.fileIdx == p.lex.config.projectMainIdx
    else:
      p.module.module.fileIdx == p.config.projectMainIdx
  elif compiles(m.module.fileIdx):
    m.module.fileIdx == m.config.projectMainIdx
  elif compiles(L.fileIdx):
    L.fileIdx == L.config.projectMainIdx
  else:
    error()

# --------------------------- ident tables ----------------------------------
proc idTableGet*(t: TIdTable, key: PIdObj): RootRef
proc idTableGet*(t: TIdTable, key: int): RootRef
proc idTablePut*(t: var TIdTable, key: PIdObj, val: RootRef)
proc idTableHasObjectAsKey*(t: TIdTable, key: PIdObj): bool
  # checks if `t` contains the `key` (compared by the pointer value, not only
  # `key`'s id)
proc idNodeTableGet*(t: TIdNodeTable, key: PIdObj): PNode
proc idNodeTablePut*(t: var TIdNodeTable, key: PIdObj, val: PNode)

# ---------------------------------------------------------------------------

proc getSymFromList*(list: PNode, ident: PIdent, start: int = 0): PSym
proc lookupInRecord*(n: PNode, field: PIdent): PSym
proc mustRehash*(length, counter: int): bool
proc nextTry*(h, maxHash: Hash): Hash {.inline.}

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


proc initIiTable*(x: var TIITable)
proc iiTableGet*(t: TIITable, key: int): int
proc iiTablePut*(t: var TIITable, key, val: int)

# implementation

proc skipConvAndClosure*(n: PNode): PNode =
  result = n
  while true:
    case result.kind
    of nkObjUpConv, nkObjDownConv, nkChckRange, nkChckRangeF, nkChckRange64,
       nkClosure:
      result = result.sons[0]
    of nkHiddenStdConv, nkHiddenSubConv, nkConv:
      result = result.sons[1]
    else: break

proc sameValue*(a, b: PNode): bool =
  result = false
  case a.kind
  of nkCharLit..nkUInt64Lit:
    if b.kind in {nkCharLit..nkUInt64Lit}: result = a.intVal == b.intVal
  of nkFloatLit..nkFloat64Lit:
    if b.kind in {nkFloatLit..nkFloat64Lit}: result = a.floatVal == b.floatVal
  of nkStrLit..nkTripleStrLit:
    if b.kind in {nkStrLit..nkTripleStrLit}: result = a.strVal == b.strVal
  else:
    # don't raise an internal error for 'nim check':
    #InternalError(a.info, "SameValue")
    discard

proc leValue*(a, b: PNode): bool =
  # a <= b?
  result = false
  case a.kind
  of nkCharLit..nkUInt32Lit:
    if b.kind in {nkCharLit..nkUInt32Lit}: result = a.intVal <= b.intVal
  of nkFloatLit..nkFloat64Lit:
    if b.kind in {nkFloatLit..nkFloat64Lit}: result = a.floatVal <= b.floatVal
  of nkStrLit..nkTripleStrLit:
    if b.kind in {nkStrLit..nkTripleStrLit}: result = a.strVal <= b.strVal
  else:
    # don't raise an internal error for 'nim check':
    #InternalError(a.info, "leValue")
    discard

proc weakLeValue*(a, b: PNode): TImplication =
  if a.kind notin nkLiterals or b.kind notin nkLiterals:
    result = impUnknown
  else:
    result = if leValue(a, b): impYes else: impNo

proc lookupInRecord(n: PNode, field: PIdent): PSym =
  result = nil
  case n.kind
  of nkRecList:
    for i in countup(0, sonsLen(n) - 1):
      result = lookupInRecord(n.sons[i], field)
      if result != nil: return
  of nkRecCase:
    if (n.sons[0].kind != nkSym): return nil
    result = lookupInRecord(n.sons[0], field)
    if result != nil: return
    for i in countup(1, sonsLen(n) - 1):
      case n.sons[i].kind
      of nkOfBranch, nkElse:
        result = lookupInRecord(lastSon(n.sons[i]), field)
        if result != nil: return
      else: return nil
  of nkSym:
    if n.sym.name.id == field.id: result = n.sym
  else: return nil

proc getModule*(s: PSym): PSym =
  result = s
  assert((result.kind == skModule) or (result.owner != result))
  while result != nil and result.kind != skModule: result = result.owner

proc getSymFromList(list: PNode, ident: PIdent, start: int = 0): PSym =
  for i in countup(start, sonsLen(list) - 1):
    if list.sons[i].kind == nkSym:
      result = list.sons[i].sym
      if result.name.id == ident.id: return
    else: return nil
  result = nil

proc hashNode(p: RootRef): Hash =
  result = hash(cast[pointer](p))

proc mustRehash(length, counter: int): bool =
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

proc rspaces(x: int): Rope =
  # returns x spaces
  result = rope(spaces(x))

proc toYamlChar(c: char): string =
  case c
  of '\0'..'\x1F', '\x7F'..'\xFF': result = "\\u" & strutils.toHex(ord(c), 4)
  of '\'', '\"', '\\': result = '\\' & c
  else: result = $c

proc makeYamlString*(s: string): Rope =
  # We have to split long strings into many ropes. Otherwise
  # this could trigger InternalError(111). See the ropes module for
  # further information.
  const MaxLineLength = 64
  result = nil
  var res = "\""
  for i in countup(0, if s.isNil: -1 else: (len(s)-1)):
    if (i + 1) mod MaxLineLength == 0:
      add(res, '\"')
      add(res, "\n")
      add(result, rope(res))
      res = "\""              # reset
    add(res, toYamlChar(s[i]))
  add(res, '\"')
  add(result, rope(res))

proc flagsToStr[T](flags: set[T]): Rope =
  if flags == {}:
    result = rope("[]")
  else:
    result = nil
    for x in items(flags):
      if result != nil: add(result, ", ")
      add(result, makeYamlString($x))
    result = "[" & result & "]"

proc lineInfoToStr(conf: ConfigRef; info: TLineInfo): Rope =
  result = "[$1, $2, $3]" % [makeYamlString(toFilename(conf, info)),
                             rope(toLinenumber(info)),
                             rope(toColumn(info))]

proc treeToYamlAux(conf: ConfigRef; n: PNode, marker: var IntSet,
                   indent, maxRecDepth: int): Rope
proc symToYamlAux(conf: ConfigRef; n: PSym, marker: var IntSet,
                  indent, maxRecDepth: int): Rope
proc typeToYamlAux(conf: ConfigRef; n: PType, marker: var IntSet,
                   indent, maxRecDepth: int): Rope

proc ropeConstr(indent: int, c: openArray[Rope]): Rope =
  # array of (name, value) pairs
  var istr = rspaces(indent + 2)
  result = rope("{")
  var i = 0
  while i <= high(c):
    if i > 0: add(result, ",")
    addf(result, "$N$1\"$2\": $3", [istr, c[i], c[i + 1]])
    inc(i, 2)
  addf(result, "$N$1}", [rspaces(indent)])

proc symToYamlAux(conf: ConfigRef; n: PSym, marker: var IntSet, indent: int,
                  maxRecDepth: int): Rope =
  if n == nil:
    result = rope("null")
  elif containsOrIncl(marker, n.id):
    result = "\"$1 @$2\"" % [rope(n.name.s), rope(
        strutils.toHex(cast[ByteAddress](n), sizeof(n) * 2))]
  else:
    var ast = treeToYamlAux(conf, n.ast, marker, indent + 2, maxRecDepth - 1)
    result = ropeConstr(indent, [rope("kind"),
                                 makeYamlString($n.kind),
                                 rope("name"), makeYamlString(n.name.s),
                                 rope("typ"), typeToYamlAux(conf, n.typ, marker,
                                   indent + 2, maxRecDepth - 1),
                                 rope("info"), lineInfoToStr(conf, n.info),
                                 rope("flags"), flagsToStr(n.flags),
                                 rope("magic"), makeYamlString($n.magic),
                                 rope("ast"), ast, rope("options"),
                                 flagsToStr(n.options), rope("position"),
                                 rope(n.position)])

proc typeToYamlAux(conf: ConfigRef; n: PType, marker: var IntSet, indent: int,
                   maxRecDepth: int): Rope =
  if n == nil:
    result = rope("null")
  elif containsOrIncl(marker, n.id):
    result = "\"$1 @$2\"" % [rope($n.kind), rope(
        strutils.toHex(cast[ByteAddress](n), sizeof(n) * 2))]
  else:
    if sonsLen(n) > 0:
      result = rope("[")
      for i in countup(0, sonsLen(n) - 1):
        if i > 0: add(result, ",")
        addf(result, "$N$1$2", [rspaces(indent + 4), typeToYamlAux(conf, n.sons[i],
            marker, indent + 4, maxRecDepth - 1)])
      addf(result, "$N$1]", [rspaces(indent + 2)])
    else:
      result = rope("null")
    result = ropeConstr(indent, [rope("kind"),
                                 makeYamlString($n.kind),
                                 rope("sym"), symToYamlAux(conf, n.sym, marker,
        indent + 2, maxRecDepth - 1), rope("n"), treeToYamlAux(conf, n.n, marker,
        indent + 2, maxRecDepth - 1), rope("flags"), flagsToStr(n.flags),
                                 rope("callconv"),
                                 makeYamlString(CallingConvToStr[n.callConv]),
                                 rope("size"), rope(n.size),
                                 rope("align"), rope(n.align),
                                 rope("sons"), result])

proc treeToYamlAux(conf: ConfigRef; n: PNode, marker: var IntSet, indent: int,
                   maxRecDepth: int): Rope =
  if n == nil:
    result = rope("null")
  else:
    var istr = rspaces(indent + 2)
    result = "{$N$1\"kind\": $2" % [istr, makeYamlString($n.kind)]
    if maxRecDepth != 0:
      addf(result, ",$N$1\"info\": $2", [istr, lineInfoToStr(conf, n.info)])
      case n.kind
      of nkCharLit..nkInt64Lit:
        addf(result, ",$N$1\"intVal\": $2", [istr, rope(n.intVal)])
      of nkFloatLit, nkFloat32Lit, nkFloat64Lit:
        addf(result, ",$N$1\"floatVal\": $2",
            [istr, rope(n.floatVal.toStrMaxPrecision)])
      of nkStrLit..nkTripleStrLit:
        if n.strVal.isNil:
          addf(result, ",$N$1\"strVal\": null", [istr])
        else:
          addf(result, ",$N$1\"strVal\": $2", [istr, makeYamlString(n.strVal)])
      of nkSym:
        addf(result, ",$N$1\"sym\": $2",
             [istr, symToYamlAux(conf, n.sym, marker, indent + 2, maxRecDepth)])
      of nkIdent:
        if n.ident != nil:
          addf(result, ",$N$1\"ident\": $2", [istr, makeYamlString(n.ident.s)])
        else:
          addf(result, ",$N$1\"ident\": null", [istr])
      else:
        if sonsLen(n) > 0:
          addf(result, ",$N$1\"sons\": [", [istr])
          for i in countup(0, sonsLen(n) - 1):
            if i > 0: add(result, ",")
            addf(result, "$N$1$2", [rspaces(indent + 4), treeToYamlAux(conf, n.sons[i],
                marker, indent + 4, maxRecDepth - 1)])
          addf(result, "$N$1]", [istr])
      addf(result, ",$N$1\"typ\": $2",
           [istr, typeToYamlAux(conf, n.typ, marker, indent + 2, maxRecDepth)])
    addf(result, "$N$1}", [rspaces(indent)])

proc treeToYaml(conf: ConfigRef; n: PNode, indent: int = 0, maxRecDepth: int = - 1): Rope =
  var marker = initIntSet()
  result = treeToYamlAux(conf, n, marker, indent, maxRecDepth)

proc typeToYaml(conf: ConfigRef; n: PType, indent: int = 0, maxRecDepth: int = - 1): Rope =
  var marker = initIntSet()
  result = typeToYamlAux(conf, n, marker, indent, maxRecDepth)

proc symToYaml(conf: ConfigRef; n: PSym, indent: int = 0, maxRecDepth: int = - 1): Rope =
  var marker = initIntSet()
  result = symToYamlAux(conf, n, marker, indent, maxRecDepth)

proc debugTree*(conf: ConfigRef; n: PNode, indent: int, maxRecDepth: int; renderType=false): Rope
proc debugType(conf: ConfigRef; n: PType, maxRecDepth=100): Rope =
  if n == nil:
    result = rope("null")
  else:
    result = rope($n.kind)
    if n.sym != nil:
      add(result, " ")
      add(result, n.sym.name.s)
    if n.kind in IntegralTypes and n.n != nil:
      add(result, ", node: ")
      add(result, debugTree(conf, n.n, 2, maxRecDepth-1, renderType=true))
    if (n.kind != tyString) and (sonsLen(n) > 0) and maxRecDepth != 0:
      add(result, "(")
      for i in countup(0, sonsLen(n) - 1):
        if i > 0: add(result, ", ")
        if n.sons[i] == nil:
          add(result, "null")
        else:
          add(result, debugType(conf, n.sons[i], maxRecDepth-1))
      if n.kind == tyObject and n.n != nil:
        add(result, ", node: ")
        add(result, debugTree(conf, n.n, 2, maxRecDepth-1, renderType=true))
      add(result, ")")

proc debugTree(conf: ConfigRef; n: PNode, indent: int, maxRecDepth: int;
               renderType=false): Rope =
  if n == nil:
    result = rope("null")
  else:
    var istr = rspaces(indent + 2)
    result = "{$N$1\"kind\": $2" %
             [istr, makeYamlString($n.kind)]
    when defined(useNodeIds):
      addf(result, ",$N$1\"id\": $2", [istr, rope(n.id)])
    addf(result, ",$N$1\"info\": $2", [istr, lineInfoToStr(conf, n.info)])
    if maxRecDepth != 0:
      addf(result, ",$N$1\"flags\": $2", [istr, rope($n.flags)])
      case n.kind
      of nkCharLit..nkUInt64Lit:
        addf(result, ",$N$1\"intVal\": $2", [istr, rope(n.intVal)])
      of nkFloatLit, nkFloat32Lit, nkFloat64Lit:
        addf(result, ",$N$1\"floatVal\": $2",
            [istr, rope(n.floatVal.toStrMaxPrecision)])
      of nkStrLit..nkTripleStrLit:
        if n.strVal.isNil:
          addf(result, ",$N$1\"strVal\": null", [istr])
        else:
          addf(result, ",$N$1\"strVal\": $2", [istr, makeYamlString(n.strVal)])
      of nkSym:
        addf(result, ",$N$1\"sym\": $2_$3",
            [istr, rope(n.sym.name.s), rope(n.sym.id)])
        #     [istr, symToYaml(n.sym, indent, maxRecDepth),
        #     rope(n.sym.id)])
        if renderType and n.sym.typ != nil:
          addf(result, ",$N$1\"typ\": $2", [istr, debugType(conf, n.sym.typ, 2)])
      of nkIdent:
        if n.ident != nil:
          addf(result, ",$N$1\"ident\": $2", [istr, makeYamlString(n.ident.s)])
        else:
          addf(result, ",$N$1\"ident\": null", [istr])
      else:
        if sonsLen(n) > 0:
          addf(result, ",$N$1\"sons\": [", [istr])
          for i in countup(0, sonsLen(n) - 1):
            if i > 0: add(result, ",")
            addf(result, "$N$1$2", [rspaces(indent + 4), debugTree(conf, n.sons[i],
                indent + 4, maxRecDepth - 1, renderType)])
          addf(result, "$N$1]", [istr])
    addf(result, "$N$1}", [rspaces(indent)])

when declared(echo):
  proc debug(conf: ConfigRef; n: PSym) =
    if n == nil:
      echo("null")
    elif n.kind == skUnknown:
      echo("skUnknown")
    else:
      #writeLine(stdout, $symToYaml(n, 0, 1))
      echo("$1_$2: $3, $4, $5, $6" % [
        n.name.s, $n.id, $flagsToStr(n.flags), $flagsToStr(n.loc.flags),
        $lineInfoToStr(conf, n.info), $n.kind])

  proc debug(conf: ConfigRef; n: PType) =
    echo($debugType(conf, n))

  proc debug(conf: ConfigRef; n: PNode) =
    echo($debugTree(conf, n, 0, 100))

proc nextTry(h, maxHash: Hash): Hash =
  result = ((5 * h) + 1) and maxHash
  # For any initial h in range(maxHash), repeating that maxHash times
  # generates each int in range(maxHash) exactly once (see any text on
  # random-number generation for proof).

proc objectSetContains*(t: TObjectSet, obj: RootRef): bool =
  # returns true whether n is in t
  var h: Hash = hashNode(obj) and high(t.data) # start with real hash value
  while t.data[h] != nil:
    if t.data[h] == obj:
      return true
    h = nextTry(h, high(t.data))
  result = false

proc objectSetRawInsert(data: var TObjectSeq, obj: RootRef) =
  var h: Hash = hashNode(obj) and high(data)
  while data[h] != nil:
    assert(data[h] != obj)
    h = nextTry(h, high(data))
  assert(data[h] == nil)
  data[h] = obj

proc objectSetEnlarge(t: var TObjectSet) =
  var n: TObjectSeq
  newSeq(n, len(t.data) * GrowthFactor)
  for i in countup(0, high(t.data)):
    if t.data[i] != nil: objectSetRawInsert(n, t.data[i])
  swap(t.data, n)

proc objectSetIncl*(t: var TObjectSet, obj: RootRef) =
  if mustRehash(len(t.data), t.counter): objectSetEnlarge(t)
  objectSetRawInsert(t.data, obj)
  inc(t.counter)

proc objectSetContainsOrIncl*(t: var TObjectSet, obj: RootRef): bool =
  # returns true if obj is already in the string table:
  var h: Hash = hashNode(obj) and high(t.data)
  while true:
    var it = t.data[h]
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

proc strTableContains*(t: TStrTable, n: PSym): bool =
  var h: Hash = n.name.h and high(t.data) # start with real hash value
  while t.data[h] != nil:
    if (t.data[h] == n):
      return true
    h = nextTry(h, high(t.data))
  result = false

proc strTableRawInsert(data: var TSymSeq, n: PSym) =
  var h: Hash = n.name.h and high(data)
  if sfImmediate notin n.flags:
    # fast path:
    while data[h] != nil:
      if data[h] == n:
        # allowed for 'export' feature:
        #InternalError(n.info, "StrTableRawInsert: " & n.name.s)
        return
      h = nextTry(h, high(data))
    assert(data[h] == nil)
    data[h] = n
  else:
    # slow path; we have to ensure immediate symbols are preferred for
    # symbol lookups.
    # consider the chain: foo (immediate), foo, bar, bar (immediate)
    # then bar (immediate) gets replaced with foo (immediate) and the non
    # immediate foo is picked! Thus we need to replace it with the first
    # slot that has in fact the same identifier stored in it!
    var favPos = -1
    while data[h] != nil:
      if data[h] == n: return
      if favPos < 0 and data[h].name.id == n.name.id: favPos = h
      h = nextTry(h, high(data))
    assert(data[h] == nil)
    data[h] = n
    if favPos >= 0: swap data[h], data[favPos]

proc symTabReplaceRaw(data: var TSymSeq, prevSym: PSym, newSym: PSym) =
  assert prevSym.name.h == newSym.name.h
  var h: Hash = prevSym.name.h and high(data)
  while data[h] != nil:
    if data[h] == prevSym:
      data[h] = newSym
      return
    h = nextTry(h, high(data))
  assert false

proc symTabReplace*(t: var TStrTable, prevSym: PSym, newSym: PSym) =
  symTabReplaceRaw(t.data, prevSym, newSym)

proc strTableEnlarge(t: var TStrTable) =
  var n: TSymSeq
  newSeq(n, len(t.data) * GrowthFactor)
  for i in countup(0, high(t.data)):
    if t.data[i] != nil: strTableRawInsert(n, t.data[i])
  swap(t.data, n)

proc strTableAdd*(t: var TStrTable, n: PSym) =
  if mustRehash(len(t.data), t.counter): strTableEnlarge(t)
  strTableRawInsert(t.data, n)
  inc(t.counter)

proc strTableIncl*(t: var TStrTable, n: PSym; onConflictKeepOld=false): bool {.discardable.} =
  # returns true if n is already in the string table:
  # It is essential that `n` is written nevertheless!
  # This way the newest redefinition is picked by the semantic analyses!
  assert n.name != nil
  var h: Hash = n.name.h and high(t.data)
  var replaceSlot = -1
  while true:
    var it = t.data[h]
    if it == nil: break
    # Semantic checking can happen multiple times thanks to templates
    # and overloading: (var x=@[]; x).mapIt(it).
    # So it is possible the very same sym is added multiple
    # times to the symbol table which we allow here with the 'it == n' check.
    if it.name.id == n.name.id:
      if it == n: return false
      replaceSlot = h
    h = nextTry(h, high(t.data))
  if replaceSlot >= 0:
    if not onConflictKeepOld:
      t.data[replaceSlot] = n # overwrite it with newer definition!
    return true             # found it
  elif mustRehash(len(t.data), t.counter):
    strTableEnlarge(t)
    strTableRawInsert(t.data, n)
  else:
    assert(t.data[h] == nil)
    t.data[h] = n
  inc(t.counter)
  result = false

proc strTableGet*(t: TStrTable, name: PIdent): PSym =
  var h: Hash = name.h and high(t.data)
  while true:
    result = t.data[h]
    if result == nil: break
    if result.name.id == name.id: break
    h = nextTry(h, high(t.data))


type
  TIdentIter* = object # iterator over all syms with same identifier
    h*: Hash           # current hash
    name*: PIdent

proc nextIdentIter*(ti: var TIdentIter, tab: TStrTable): PSym =
  var h = ti.h and high(tab.data)
  var start = h
  result = tab.data[h]
  while result != nil:
    if result.name.id == ti.name.id: break
    h = nextTry(h, high(tab.data))
    if h == start:
      result = nil
      break
    result = tab.data[h]
  ti.h = nextTry(h, high(tab.data))

proc initIdentIter*(ti: var TIdentIter, tab: TStrTable, s: PIdent): PSym =
  ti.h = s.h
  ti.name = s
  if tab.counter == 0: result = nil
  else: result = nextIdentIter(ti, tab)

proc nextIdentExcluding*(ti: var TIdentIter, tab: TStrTable,
                         excluding: IntSet): PSym =
  var h: Hash = ti.h and high(tab.data)
  var start = h
  result = tab.data[h]
  while result != nil:
    if result.name.id == ti.name.id and not contains(excluding, result.id):
      break
    h = nextTry(h, high(tab.data))
    if h == start:
      result = nil
      break
    result = tab.data[h]
  ti.h = nextTry(h, high(tab.data))
  if result != nil and contains(excluding, result.id): result = nil

proc firstIdentExcluding*(ti: var TIdentIter, tab: TStrTable, s: PIdent,
                          excluding: IntSet): PSym =
  ti.h = s.h
  ti.name = s
  if tab.counter == 0: result = nil
  else: result = nextIdentExcluding(ti, tab, excluding)

type
  TTabIter* = object
    h: Hash

proc nextIter*(ti: var TTabIter, tab: TStrTable): PSym =
  # usage:
  # var
  #   i: TTabIter
  #   s: PSym
  # s = InitTabIter(i, table)
  # while s != nil:
  #   ...
  #   s = NextIter(i, table)
  #
  result = nil
  while (ti.h <= high(tab.data)):
    result = tab.data[ti.h]
    inc(ti.h)                 # ... and increment by one always
    if result != nil: break

proc initTabIter*(ti: var TTabIter, tab: TStrTable): PSym =
  ti.h = 0
  if tab.counter == 0:
    result = nil
  else:
    result = nextIter(ti, tab)

iterator items*(tab: TStrTable): PSym =
  var it: TTabIter
  var s = initTabIter(it, tab)
  while s != nil:
    yield s
    s = nextIter(it, tab)

proc hasEmptySlot(data: TIdPairSeq): bool =
  for h in countup(0, high(data)):
    if data[h].key == nil:
      return true
  result = false

proc idTableRawGet(t: TIdTable, key: int): int =
  var h: Hash
  h = key and high(t.data)    # start with real hash value
  while t.data[h].key != nil:
    if t.data[h].key.id == key:
      return h
    h = nextTry(h, high(t.data))
  result = - 1

proc idTableHasObjectAsKey(t: TIdTable, key: PIdObj): bool =
  var index = idTableRawGet(t, key.id)
  if index >= 0: result = t.data[index].key == key
  else: result = false

proc idTableGet(t: TIdTable, key: PIdObj): RootRef =
  var index = idTableRawGet(t, key.id)
  if index >= 0: result = t.data[index].val
  else: result = nil

proc idTableGet(t: TIdTable, key: int): RootRef =
  var index = idTableRawGet(t, key)
  if index >= 0: result = t.data[index].val
  else: result = nil

iterator pairs*(t: TIdTable): tuple[key: int, value: RootRef] =
  for i in 0..high(t.data):
    if t.data[i].key != nil:
      yield (t.data[i].key.id, t.data[i].val)

proc idTableRawInsert(data: var TIdPairSeq, key: PIdObj, val: RootRef) =
  var h: Hash
  h = key.id and high(data)
  while data[h].key != nil:
    assert(data[h].key.id != key.id)
    h = nextTry(h, high(data))
  assert(data[h].key == nil)
  data[h].key = key
  data[h].val = val

proc idTablePut(t: var TIdTable, key: PIdObj, val: RootRef) =
  var
    index: int
    n: TIdPairSeq
  index = idTableRawGet(t, key.id)
  if index >= 0:
    assert(t.data[index].key != nil)
    t.data[index].val = val
  else:
    if mustRehash(len(t.data), t.counter):
      newSeq(n, len(t.data) * GrowthFactor)
      for i in countup(0, high(t.data)):
        if t.data[i].key != nil:
          idTableRawInsert(n, t.data[i].key, t.data[i].val)
      assert(hasEmptySlot(n))
      swap(t.data, n)
    idTableRawInsert(t.data, key, val)
    inc(t.counter)

iterator idTablePairs*(t: TIdTable): tuple[key: PIdObj, val: RootRef] =
  for i in 0 .. high(t.data):
    if not isNil(t.data[i].key): yield (t.data[i].key, t.data[i].val)

proc idNodeTableRawGet(t: TIdNodeTable, key: PIdObj): int =
  var h: Hash
  h = key.id and high(t.data) # start with real hash value
  while t.data[h].key != nil:
    if t.data[h].key.id == key.id:
      return h
    h = nextTry(h, high(t.data))
  result = - 1

proc idNodeTableGet(t: TIdNodeTable, key: PIdObj): PNode =
  var index: int
  index = idNodeTableRawGet(t, key)
  if index >= 0: result = t.data[index].val
  else: result = nil

proc idNodeTableGetLazy*(t: TIdNodeTable, key: PIdObj): PNode =
  if not isNil(t.data):
    result = idNodeTableGet(t, key)

proc idNodeTableRawInsert(data: var TIdNodePairSeq, key: PIdObj, val: PNode) =
  var h: Hash
  h = key.id and high(data)
  while data[h].key != nil:
    assert(data[h].key.id != key.id)
    h = nextTry(h, high(data))
  assert(data[h].key == nil)
  data[h].key = key
  data[h].val = val

proc idNodeTablePut(t: var TIdNodeTable, key: PIdObj, val: PNode) =
  var index = idNodeTableRawGet(t, key)
  if index >= 0:
    assert(t.data[index].key != nil)
    t.data[index].val = val
  else:
    if mustRehash(len(t.data), t.counter):
      var n: TIdNodePairSeq
      newSeq(n, len(t.data) * GrowthFactor)
      for i in countup(0, high(t.data)):
        if t.data[i].key != nil:
          idNodeTableRawInsert(n, t.data[i].key, t.data[i].val)
      swap(t.data, n)
    idNodeTableRawInsert(t.data, key, val)
    inc(t.counter)

proc idNodeTablePutLazy*(t: var TIdNodeTable, key: PIdObj, val: PNode) =
  if isNil(t.data): initIdNodeTable(t)
  idNodeTablePut(t, key, val)

iterator pairs*(t: TIdNodeTable): tuple[key: PIdObj, val: PNode] =
  for i in 0 .. high(t.data):
    if not isNil(t.data[i].key): yield (t.data[i].key, t.data[i].val)

proc initIITable(x: var TIITable) =
  x.counter = 0
  newSeq(x.data, StartSize)
  for i in countup(0, StartSize - 1): x.data[i].key = InvalidKey

proc iiTableRawGet(t: TIITable, key: int): int =
  var h: Hash
  h = key and high(t.data)    # start with real hash value
  while t.data[h].key != InvalidKey:
    if t.data[h].key == key: return h
    h = nextTry(h, high(t.data))
  result = -1

proc iiTableGet(t: TIITable, key: int): int =
  var index = iiTableRawGet(t, key)
  if index >= 0: result = t.data[index].val
  else: result = InvalidKey

proc iiTableRawInsert(data: var TIIPairSeq, key, val: int) =
  var h: Hash
  h = key and high(data)
  while data[h].key != InvalidKey:
    assert(data[h].key != key)
    h = nextTry(h, high(data))
  assert(data[h].key == InvalidKey)
  data[h].key = key
  data[h].val = val

proc iiTablePut(t: var TIITable, key, val: int) =
  var index = iiTableRawGet(t, key)
  if index >= 0:
    assert(t.data[index].key != InvalidKey)
    t.data[index].val = val
  else:
    if mustRehash(len(t.data), t.counter):
      var n: TIIPairSeq
      newSeq(n, len(t.data) * GrowthFactor)
      for i in countup(0, high(n)): n[i].key = InvalidKey
      for i in countup(0, high(t.data)):
        if t.data[i].key != InvalidKey:
          iiTableRawInsert(n, t.data[i].key, t.data[i].val)
      swap(t.data, n)
    iiTableRawInsert(t.data, key, val)
    inc(t.counter)
