#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
# ------------------------- Name Mangling --------------------------------
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

]##


import # compiler imports

    ast, cgendata, modulegraphs, ropes, ccgutils, ndi, msgs, incremental,
    idents, options, wordrecg, astalgo, treetab, sighashes

import # stdlib imports

  std / [ strutils, tables, sets ]

template config(): ConfigRef = cache.modules.config

using
  g: ModuleGraph

# get a unique id from a psym or ptype; these are keys in ConflictsTable
template conflictKey(s: PSym): int = s.id
template conflictKey(s: PType): int = s.uniqueId

# useful for debugging
template conflictKey(s: BModule): int = conflictKey(s.module)
template conflictKey(s: BProc): int =
  if s.prc == nil:
    0
  else:
    conflictKey(s.prc)

proc mangle*(p: ModuleOrProc; s: PSym): string

proc getSomeNameForModule*(m: PSym): string =
  assert m.kind == skModule
  assert m.owner.kind == skPackage
  if {sfSystemModule, sfMainModule} * m.flags == {}:
    result = mangle(m.owner.name.s)
    result.add "_"
    assert m.name.s.len > 0
  result.add mangle(m.name.s)

proc findPendingModule*(m: BModule, s: PSym): BModule =
  var ms = getModule(s)
  result = m.g.modules[ms.position]

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

proc getOrSet(conflicts: var ConflictsTable; name: string; key: int): int =
  ## add/get a mangled name from the conflicts table and return the number
  ## of conflicts for that name at the time of its insertion
  let key = $key
  result = getOrDefault(conflicts, key, -1)
  if result == -1:
    # start counting at zero so we can omit an initial append
    result = getOrDefault(conflicts, name, 0)
    if result == 0:
      # set the value for the name to indicate the NEXT available counter
      conflicts[name] = 1
    else:
      # this is kinda important; only an idiot would omit it on his first try
      inc conflicts[name]
    # cache the result
    conflicts[key] = result

proc purgeConflict*(m: ModuleOrProc; s: PSym) =
  del m.sigConflicts, $conflictKey(s)

proc hasImmutableName(s: PSym): bool =
  ## True if the symbol uses a name that must not change.
  const immut = {sfSystemModule, sfCompilerProc, sfImportc, sfExportc}
  if s != nil:
    result = immut * s.flags != {}
  # XXX: maybe sfGenSym means we can always mutate it?
  # XXX: is it immutable if we've already assigned it in sigConflicts?

proc shouldAppendModuleName(s: PSym): bool =
  ## are we going to apply top-level mangling semantics?
  if s.hasImmutableName:
    return false
  case s.kind
  of skLocalVars + {skModule, skPackage, skTemp}:
    result = false
  else:
    if s.owner == nil or s.owner.kind in {skModule, skPackage}:
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

proc typeName*(p: ModuleOrProc; typ: PType; shorten = false): string =
  let m = getem()
  var typ = typ.skipTypes(irrelevantForBackend)
  result = case typ.kind
  of tySet, tySequence, tyTypeDesc, tyArray:
    shortKind(typ.kind) & "_" & typeName(p, typ.lastSon, shorten = shorten)
  of tyVar, tyRef, tyPtr:
    # omit this verbosity for now
    typeName(p, typ.lastSon, shorten = shorten)
  else:
    if typ.sym == nil: # or typ.kind notin {tyObject, tyEnum}:
      shortKind(typ.kind) & "_" & $conflictKey(typ)
    elif shorten:
      mangle(typ.sym.name.s)
    else:
      mangle(p, typ.sym)

template maybeAppendCounter(result: typed; count: int) =
  if count > 0:
    result.add "_"
    result.add $count

proc maybeAppendProcArgument(m: ModuleOrProc; s: PSym; nom: var string): bool =
  ## should we add the first argument's type to the mangle?
  if s.kind in routineKinds:
    if s.typ != nil:
      result = s.typ.sons.len > 1
      if result:
        nom.add "_"
        nom.add typeName(m, s.typ.sons[1], shorten = true)

proc mangle*(p: ModuleOrProc; s: PSym): string =
  # TODO: until we have a new backend ast, all mangles have to be done
  # identically
  let m = getem()
  block:
    case s.kind
    of skProc:
      # anonymous closures are special for... reasons
      if s.name.s == ":anonymous":
        result = "anon_proc_"
        result.add $conflictKey(s)
        break
      # closures are great for link collisions
      elif sfAddrTaken in s.flags:
        result = mangle(s.name.s)
        result.add "_"
        result.add $conflictKey(s)
        assert not s.hasImmutableName
        break
    of skIterator:
      # iterators need a special treatment for linking reasons
      result = mangle(s.name.s)
      result.add "_"
      result.add $conflictKey(s)
      assert not s.hasImmutableName
      break
    else:
      discard

    # otherwise, start off by using a name that doesn't suck
    result = mangle(s.name.s)

    # a gensym is a good sign that we can encounter a link collision
    if {sfGenSym} * s.flags != {}:
      assert not s.hasImmutableName
      result.add "_"
      result.add $conflictKey(s)
      # let's just get out of here rather than making this any worse
      return

  # some symbols have flags that preclude further mangling
  if not s.hasImmutableName:

    # add the first argument to procs if possible
    discard maybeAppendProcArgument(m, s, result)

    # add the module name if necessary, or if it helps avoid a clash
    if shouldAppendModuleName(s) or isNimOrCKeyword(s.name):
      let parent = findPendingModule(m, s)
      if parent != nil:
        result.add "_"
        result.add getSomeNameForModule(parent.module)

    # something like `default` might need this check
    if (unlikely) result in m.config.cppDefines:
      result.add "_"
      result.add $conflictKey(s)

  #if getModule(s).id.abs != m.module.id.abs: ...creepy for IC...
  # XXX: we don't do anything special with regard to m.hcrOn
  assert result.len > 0

when not nimIncremental:
  proc getConflictFromCache(g: ModuleGraph; s: PSym): int =
    discard
else:
  import std/db_sqlite

  proc getConflictFromCache(g: ModuleGraph; s: PSym): int =
    template db(): DbConn = g.incr.db
    const
      query = sql"""
        select id from conflicts
        where nimid = ?
        order by id desc
        limit 1
      """
      insert = sql"""
        insert into conflicts (nimid)
        values (?)
      """
    let id = db.getValue(query, s.id)
    if id == "":
      # set the counter to the row id, not the symbol id or the actual count
      result = db.insertID(insert, s.id).int
    else:
      result = id.parseInt
    assert result > 0

proc getSetConflict(p: ModuleOrProc; s: PSym): tuple[name: string; counter: int] =
  ## take a backend module or a procedure being generated and produce an
  ## appropriate name and the instances of its occurence, which may be
  ## incremented for this instance
  let m = getem()
  template g(): ModuleGraph = m.g.graph
  var counter = -1         # the current counter for this name
  var next = 1             # the next counter for this name

  # we always mangle it anew, which is kinda sad
  var name = mangle(p, s)
  let key = $conflictKey(s)

  block:
    when p is BModule:
      if g.config.symbolFiles != disabledSf:
        # we can use the IC cache to determine the right name and counter
        # for this symbol, but only for module-level manglings
        counter = getConflictFromCache(g, s)
        # FIXME: add a compiler pass to warm up the conflicts cache
        break

    # critically, we must check for conflicts at the source module
    # in the event a global symbol is actually foreign to `p`
    if sfGlobal in s.flags:
      var parent = findPendingModule(m, s)
      # is it foreign?  terribly expensive, i know.
      if parent.cfilename.string != m.cfilename.string:
        # use or set the existing foreign counter for the key
        (name, counter) = getSetConflict(parent, s)
        # use or set the existing foreign counter for the name
        next = mgetOrPut(parent.sigConflicts, name, counter + 1)
        break

  # we're kinda cheating here; this caches the symbol for write at file close
  if s.kind != skTemp:
    writeMangledName(m.ndi, s, m.config)

  # if the counter hasn't been set from a foreign or cached symbol,
  if counter == -1:
    # set it using the local conflicts table
    counter = getOrSet(p.sigConflicts, name, conflictKey(s))
  else:
    # else, stuff it into the local table with the discovered counter
    p.sigConflicts[key] = counter

    # set the next value to the larger of the local and remote values
    let existing = getOrDefault(p.sigConflicts, name, 1)
    while next <= counter or next < existing:
      inc next

    # now we can set the next value locally
    p.sigConflicts[name] = next

  result = (name: name, counter: counter)

proc idOrSig*(m: ModuleOrProc; s: PSym): Rope =
  ## produce a unique identity-or-signature for the given module and symbol
  let conflict = getSetConflict(m, s)
  result = conflict.name.rope
  result.maybeAppendCounter conflict.counter
  when false: # just to irritate the god of minimal debugging output
    if startsWith(conflict.name, "rand"):
      debug s
      when m is BModule:
        echo "module $4 >> $1 .. $2 -> $3" %
          [ $conflictKey(s), s.name.s, $result, $conflictKey(m.module) ]
      else:
        #result = "/*" & $conflictKey(s) & "*/" & result
        echo "  proc $4 >> $1 .. $2 -> $3" %
          [ $conflictKey(s), s.name.s, $result,
           if m.prc != nil: $conflictKey(m.prc) else: "(nil)" ]

proc getTypeName*(m: BModule; typ: PType; sig: SigHash): Rope =
  ## produce a useful name for the given type, obvs
  var key = $conflictKey(typ)
  block found:
    # try to find the actual type
    var t = typ
    while true:
      # use an immutable symbol name if we find one
      if t.sym.hasImmutableName:
        assert t.sym.loc.r != nil
        result = t.sym.loc.r
        m.sigConflicts[key] = conflictKey(t.sym)
        #echo "immutable ", key, " is ", conflictKey(t.sym), " ", result
        break found
      elif t.kind in irrelevantForBackend:
        t = t.lastSon    # continue into more precise types
      else:
        break            # this looks like a good place to stop

    assert t != nil
    result = typeName(m, t).rope
    #echo "otherwise ", key, " is ", conflictKey(t), " ", result
    let counter = getOrSet(m.sigConflicts, $result, conflictKey(t))
    result.maybeAppendCounter counter
    #result.add "/*" & $key & "*/"

  if result == nil:
    internalError(m.config, "getTypeName: " & $typ.kind)

template tempNameForLabel(m: BModule; label: int): string =
  ## create an appropriate temporary name for the given label
  m.tmpBase & $label & "_"

proc hasTempName*(m: BModule; n: PNode): bool =
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

proc mangleName*(m: ModuleOrProc; s: PSym): Rope =
  ## Mangle the symbol name and set a new location rope for it, returning
  ## same.  Has no effect if the symbol already has a location rope.
  if s.loc.r == nil:
    when m is BModule:
      # skParam is valid for global object fields with proc types
      #assert s.kind notin {skParam, skResult}
      assert s.kind notin {skResult}
    when m is BProc:
      assert s.kind notin {skModule, skPackage}
    s.loc.r = idOrSig(m, s)
  result = s.loc.r

    #[

     2020-06-11: leaving this here because it explains a real scenario,
                 but it remains to be seen if we'll still have this problem
                 after the new mangling processes the symbols; ie. why is
                 HCR special?

     Take into account if HCR is on because of the following scenario:

     if a module gets imported and it has some more importc symbols in it,
     some param names might receive the "_0" suffix to distinguish from
     what is newly available. That might lead to changes in the C code
     in nimcache that contain only a parameter name change, but that is
     enough to mandate recompilation of that source file and thus a new
     shared object will be relinked. That may lead to a module getting
     reloaded which wasn't intended and that may be fatal when parts of
     the current active callstack when performCodeReload() was called are
     from the module being reloaded unintentionally - example (3 modules
     which import one another):

       main => proxy => reloadable

     we call performCodeReload() in proxy to reload only changes in
     reloadable but there is a new import which introduces an importc
     symbol `socket` and a function called in main or proxy uses `socket`
     as a parameter name. That would lead to either needing to reload
     `proxy` or to overwrite the executable file for the main module,
     which is running (or both!) -> error.

    ]#

proc mangleField*(m: BModule; name: PIdent): string =
  ## Mangle a field to ensure it is a valid name in the backend.
  result = mangle(name.s)
  #[
   Fields are tricky to get right and thanks to generic types producing
   duplicates we can end up mangling the same field multiple times.
   However if we do so, the 'cppDefines' table might be modified in the
   meantime meaning we produce inconsistent field names (see bug #5404).
   Hence we do not check for ``m.g.config.cppDefines.contains(result)``
   here anymore:
  ]#
  if isNimOrCKeyword(name):
    result.add "_0"

proc mangleRecFieldName*(m: BModule; field: PSym): Rope =
  ## Mangle an object field to ensure it is a valid name in the backend.
  if {sfImportc, sfExportc} * field.flags != {}:
    result = field.loc.r
  else:
    result = mangleField(m, field.name).rope
  if result == nil:
    internalError(m.config, field.info, "mangleRecFieldName")

proc assignParam*(p: BProc, s: PSym; ret: PType) =
  ## Push the mangled name into the proc's sigConflicts so that we can
  ## make new local identifiers of the same name without colliding with it.
  # It's very possible that the symbol is already in the module scope!
  if s.loc.r == nil or $conflictKey(s) notin p.sigConflicts:
    purgeConflict(p.module, s)   # discard any existing counter for this sym
    if s.kind == skResult:
      s.loc.r = ~"result"
    else:
      s.loc.r = nil              # from the parent module as we move it local
      s.loc.r = mangleName(p, s) # and force the new location like a punk
  if s.loc.r == nil:
    internalError(p.config, s.info, "assignParam")

proc mangleParamName*(p: ModuleOrProc; s: PSym): Rope =
  ## we should be okay with just a simple mangle here for prototype
  ## purposes; the real meat happens in assignParam later...
  if s.loc.r == nil:
    s.loc.r = mangle(p, s).rope
  result = s.loc.r
  if result == nil:
    internalError(p.config, s.info, "mangleParamName")
