import # compiler imports

    ast, cgendata, sighashes, options, modulegraphs, ropes, pathutils,
    ccgutils, extccomp, ndi, msgs, btrees, nversion, condsyms, lineinfos,
    incremental, idgen, idents, magicsys, astalgo, options, treetab,
    wordrecg

import # stdlib imports

  std / [ db_sqlite, macros, strutils, intsets, tables, sets, sequtils ]

##[

cgendata defines ConflictsTable as Table[string, int]

The key has one of two forms:
  "SomeMangledName" -> the output of mangle() on a symbol
  "######" -> a series of digits representing a unique symbol or type id

The values have different meanings depending upon the form of the key:
  "SomeMangledName" -> the value represents the next available counter
  "######" -> the value represents the counter associated with the id

The counter is used to keep track of the order of symbol additions to the
conflict table; they are increasing but not guaranteed to be sequential.

API:

sigConflicts[PSym]: int -> yield the counter for the symbol; raise
KeyError if it hasn't been mangled yet

sigConflicts[PType]: int -> yield the counter for the type; raise KeyError
if it hasn't been mangled yet

idOrSig(BModule or BProc, PSym): string -> yield the mangled symbol name

]##

type
  ModuleOrProc = BModule or BProc

template config(): ConfigRef = cache.modules.config

using
  g: ModuleGraph

proc isNimOrCKeyword*(w: PIdent): bool =
  # Nim and C++ share some keywords
  # it's more efficient to test the whole Nim keywords range
  case w.id
  of ccgKeywordsLow..ccgKeywordsHigh:
    true
  of nimKeywordsLow..nimKeywordsHigh:
    true
  of ord(wInline):
    true
  else:
    false

# get a unique id from a psym or ptype; these are keys in ConflictsTable
template conflictKey(s: PSym): int = s.id
template conflictKey(s: PType): int = s.uniqueId

proc mangle*(m: ModuleOrProc; s: PSym): string

proc getOrSet(conflicts: var ConflictsTable; name: string; key: int): int =
  ## add/get a mangled name from the conflicts table and return the number
  ## of conflicts for that name at the time of its insertion
  let key = $key
  result = getOrDefault(conflicts, key, -1)
  if result == -1:
    # start counting at zero so we can omit an initial append
    result = getOrDefault(conflicts, name, 0)
    if result == 0:
      # set the value for the name indicate the NEXT available counter
      conflicts[name] = 1
    # cache the result
    conflicts[key] = result

proc `[]`*(conflicts: ConflictsTable; s: PSym or PType): int =
  ## returns the number of collisions at the time the symbol|type was added to
  ## the conflicts table
  result = conflicts[conflictKey(s)]

proc purgeConflict*(m: ModuleOrProc; s: PSym) =
  del m.sigConflicts, $conflictKey(s)

proc shouldAppendModuleName(s: PSym): bool =
  ## are we going to apply top-level mangling semantics?
  const
    never = {sfSystemModule, sfCompilerProc, sfImportc, sfExportc}
  # FIXME: put sfExported into never?
  case s.kind
  of skLocalVars + {skModule, skPackage, skTemp, skParam}:
    result = false
  else:
    if never * s.flags != {}:
      # the symbol uses a name that must not change
      return
    elif s.owner == nil or s.owner.kind in {skModule, skPackage}:
      # the symbol is top-level; add the module name
      result = true
    elif s.kind in routineKinds:
      if s.typ != nil:

        # this minor hack is necessary to make tests/collections/thashes
        # compile. The inlined hash function's original module is
        # ambiguous so we end up generating duplicate names otherwise:

        if s.typ.callConv == ccInline:
          result = true

    # exports get their source module appended
    if sfExported in s.flags:
      result = true

const
  irrelevantForBackend* = {tyGenericBody, tyGenericInst, tyOwned,
                           tyGenericInvocation, tyDistinct, tyRange,
                           tyStatic, tyAlias, tySink, tyInferred}

proc shortKind(k: TTypeKind): string =
  # tell me about it.
  result = $k
  result = result[2 .. min(4, result.high)].toLowerAscii

proc typeName(m: ModuleOrProc; typ: PType; shorten = false): string =
  var typ = typ.skipTypes(irrelevantForBackend)
  case typ.kind
  of tySet, tySequence, tyTypeDesc, tyArray:
    result = shortKind(typ.kind)
    result.add "_"
    result.add typeName(m, typ.lastSon, shorten = shorten)
  of tyVar, tyRef, tyPtr:
    # omit this verbosity for now
    result = typeName(m, typ.lastSon, shorten = shorten)
  else:
    if typ.sym == nil: # or typ.kind notin {tyObject, tyEnum}:
      result = shortKind(typ.kind) & "_" & $conflictKey(typ)
    elif shorten:
      result = mangle(typ.sym.name.s)
    else:
      result = mangle(m, typ.sym)

template maybeAppendCounter(result: typed; count: int) =
  if count > 0:
    result.add "_"
    result.add $count

proc getTypeName(m: BModule; typ: PType): Rope =
  block found:
    # XXX: is this safe (enough)?
    #if typ.loc.r != nil:
    #  break

    # try to find the actual type
    var t = typ
    while t != nil:
      # settle for a symbol if we can find one
      if t.sym != nil:
        if {sfImportc, sfExportc} * t.sym.flags != {}:
          result =
            if t.sym.loc.r != nil:
              # use an existing name if previously mangled
              t.sym.loc.r
            else:
              # else mangle up a new name
              mangle(m, t.sym).rope
          break found
      if t.kind notin irrelevantForBackend:
        # this looks like a good place to stop
        break
      # continue into more precise types
      t = t.lastSon

    assert t != nil
    result =
      if t.loc.r == nil:
        # create one using the closest type
        typeName(m, t).rope
      else:
        # use the closest type which already has a name
        t.loc.r

  if result == nil:
    internalError(m.config, "getTypeName: " & $typ.kind)
  else:
    typ.loc.r = result
    let counter = getOrSet(m.sigConflicts, $result, conflictKey(typ))
    result.maybeAppendCounter counter

proc getTypeName*(m: BModule; typ: PType; sig: SigHash): Rope
  {.error: "remove SigHash argument".} =
  result = getTypeName(m, typ)

proc maybeAppendProcArgument(m: ModuleOrProc; s: PSym; nom: var string): bool =
  ## should we add the first argument's type to the mangle?
  assert s.kind in routineKinds
  assert s.typ != nil
  if s.typ.sons.len > 1:
    nom.add "_"
    nom.add typeName(m, s.typ.sons[1], shorten = true)
    result = true

proc mangle*(m: ModuleOrProc; s: PSym): string =
  # TODO: until we have a new backend ast, all mangles have to be done
  # identically

  # start off by using a name that doesn't suck
  result = mangle(s.name.s)

  # add the first argument to procs if possible
  if s.kind in routineKinds and s.typ != nil:
    discard maybeAppendProcArgument(m, s, result)

  # add the module name if necessary, or if it helps avoid a clash
  if shouldAppendModuleName(s) or isNimOrCKeyword(s.name):
    let parent = getModule(s)
    if parent != nil:
      result.add "_"
      result.add mangle(parent.name.s)

  # something like `default` might need this check
  if (unlikely) result in m.config.cppDefines:
    result.add "_"
    result.add $conflictKey(s)

  #if getModule(s).id.abs != m.module.id.abs:
  # XXX: we don't do anything special with regard to m.hcrOn (Hot Code Reload)
  assert result.len > 0

when not nimIncremental:
  proc setConflictFromCache(m: BModule; s: PSym; name: string; create = true) = discard
else:
  proc setConflictFromCache(m: BModule; s: PSym; name: string; create = true) =
    template g(): ModuleGraph = m.g.graph
    template db(): DbConn = g.incr.db
    var counter: int
    let key = $conflictKey(s)

    const
      query = sql"""
        select id from conflicts
        where nimid = ?
        order by id desc
        limit 1
      """
      insert = sql"""
        insert into conflicts (nimid, name)
        values (?, ?, ?)
      """
    let id = db.getValue(query, key)
    if id == "":
      if not create:
        assert false, "missing id for " & result & " and no create option"
      # set the counter to the row id, not the symbol id or the actual count
      counter = db.insertID(insert, key, name).int
    else:
      counter = id.parseInt
    assert counter > 0

    # cache the counter associated with the key; the counter we used
    assert key notin m.sigConflicts
    m.sigConflicts[key] = counter

proc getSetConflict(p: ModuleOrProc; s: PSym;
                    create = true): tuple[name: string; counter: int] =
  ## take a backend module or a procedure being generated and produce an
  ## appropriate name and the instances of its occurence, which may be
  ## incremented for this instance
  template m(): BModule =
    when p is BModule:
      p
    else:
      p.module
  template g(): ModuleGraph = m.g.graph
  var counter: int
  var name = mangle(p, s)

  when p is BModule:
    if g.config.symbolFiles != disabledSf:
      # we can use the IC cache to determine the right name and counter
      # for this symbol, but only for module-level manglings
      setConflictFromCache(m, s, name, create = create)

  counter = getOrSet(p.sigConflicts, name, conflictKey(s))
  if counter == 0:
    # it's the first instance using this name
    if not create:
      debug s
      assert false, "cannot find existing name for: " & name
  result = (name: name, counter: counter)
  # FIXME: add a compiler pass to warm up the conflicts cache

proc idOrSig*(m: ModuleOrProc; s: PSym): Rope =
  ## produce a unique identity-or-signature for the given module and symbol
  let conflict = getSetConflict(m, s, create = true)
  result = conflict.name.rope
  result.maybeAppendCounter conflict.counter

template tempNameForLabel(m: BModule; label: int): string =
  ## create an appropriate temporary name for the given label
  m.tmpBase & $label & "_"

proc hasTempName(m: BModule; n: PNode): bool =
  ## true if the module/proc has a temporary cached for the given node
  result = nodeTableGet(m.dataCache, n) != low(int)

proc getTempNameImpl(m: BModule; id: int): string =
  ## the only way to create a new temporary name in a given module
  assert id == m.labels
  # it's a new temporary; increment our counter
  inc m.labels
  # get the appropriate name
  result = tempNameForLabel(m, id)
  # (result ends in _)
  # make sure it's not in the conflicts table
  assert result notin m.sigConflicts
  # put it in the conflicts table with the NEXT available counter
  m.sigConflicts[result] = 1

proc getTempName*(m: BModule; n: PNode; r: var Rope): bool =
  ## create or retrieve a temporary name for the given node; returns
  ## true if a new name was created and false otherwise.  appends the
  ## name to the given rope.
  let id = nodeTableTestOrSet(m.dataCache, n, m.labels)
  var name: string
  if id == m.labels:
    name = getTempNameImpl(m, id)
    result = true
  else:
    name = tempNameForLabel(m, id)
    # make sure it's not in the conflicts table under a different id
    assert getOrDefault(m.sigConflicts, name, 1) == 1
    # make sure it's in the conflicts table with the NEXT available counter
    if m.sigConflicts[name] != 1:
      writeStackTrace()
      quit(1)
    m.sigConflicts[name] = 1

  # add or append it to the result
  if r == nil:
    r = name.rope
  else:
    r.add name

proc getTempName*(m: BModule; n: PNode): Rope =
  ## a simpler getTempName that doesn't care where the name comes from
  discard getTempName(m, n, result)

proc getTempName*(m: BModule): Rope =
  ## a factory for making temporary names for use in the backend; this mutates
  ## the module from which the name originates; this always creates a new name
  result = getTempNameImpl(m, m.labels).rope
