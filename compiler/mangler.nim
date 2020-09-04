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

const
  nimDebugMangle {.strdefine.} = ""

type
  ModuleOrProc* = concept m
    m.sigConflicts is ConflictsTable

  BackendModule = concept m    ##
    ## BModule in C or JavaScript backends
    m.sigConflicts is ConflictsTable
    m.module is PSym
    m.config is ConfigRef

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
proc mangleName*(p: ModuleOrProc; s: PSym): Rope

proc getSomeNameForModule*(m: PSym): string =
  assert m.kind == skModule
  assert m.owner.kind == skPackage
  if {sfSystemModule, sfMainModule} * m.flags == {}:
    result = mangle(m.owner.name.s)
    result.add "_"
    assert m.name.s.len > 0
  result.add mangle(m.name.s)
  if result.startsWith("stdlib_"):
    # replaceWord will consume _ :-(
    result = "std_" & result[len("stdlib_") .. ^1]

proc findPendingModule*(m: BModule, s: PSym): BModule =
  var ms = getModule(s)
  result = m.g.modules[ms.position]

proc findPendingModule*[Js: BackendModule](m: Js; s: PSym): Js =
  var ms = getModule(s)
  if m.module.id == ms.id:
    result = m
  else:
    discard "no way to determine pending module in javascript"

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
    # special-casing FlowVars because they are special-cased in pragmas...
    if sfCompilerProc in s.flags:
      if not s.typ.isNil and s.typ.kind == tyGenericBody:
        assert s.name.s == "FlowVar", "unexpected generic compiler proc"
        return false
    result = immut * s.flags != {}

proc shouldAppendModuleName(s: PSym): bool =
  ## are we going to apply top-level mangling semantics?
  assert not s.hasImmutableName
  case s.kind
  of skParam, skResult, skModule, skPackage, skTemp:
    result = false
  else:
    if s.owner == nil or s.owner.kind in {skModule, skPackage}:
      # the symbol is top-level; add the module name
      result = true
    elif {sfGlobal, sfGeneratedOp} * s.flags != {}:
      # the symbol is top-level; add the module name
      result = true
    elif s.kind == skForVar:
      # forvars get special handling due to the fact that they
      # can, in rare and stupid cases, be globals...
      result = false
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
  ## truncate types
  result = toLowerAscii($k)
  removePrefix(result, "ty")
  if len(result) > 4:
    result = split(result, {'e','i','o','u'}).join("")

proc typeName*(p: ModuleOrProc; typ: PType; shorten = false): string =
  let m = getem()
  var typ = typ.skipTypes(irrelevantForBackend)
  result = case typ.kind
  of tySet, tySequence, tyTypeDesc, tyArray:
    shortKind(typ.kind) & "_" & typeName(p, typ.lastSon, shorten = shorten)
  of tyVar, tyRef, tyPtr:
    # omit this verbosity for now
    typeName(p, typ.lastSon, shorten = shorten)
  of tyProc, tyTuple:
    # gave up on making this work for now;
    #
    # the solution is probably to compose a name without regard to the
    # symbol and then simply use a signature-derived value for the
    # conflictKey of tuples and procs...
    if true or m.config.backend == backendCpp:
      # these need a signature-based name so that type signatures match :-(
      shortKind(typ.kind) & $hashType(typ)
    else:
      shortKind(typ.kind) & "_" & $conflictKey(typ)
  else:
    if typ.sym == nil:
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
        # avoid including the conflictKey of param
        if s.typ.sym == nil:
          nom.add shortKind(s.typ.kind)
        else:
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
        result = "lambda_"
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
    if sfGenSym in s.flags:
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

    # for c-ish backends, "main" is already defined, of course
    elif s.name.s == "main":
      let parent = findPendingModule(m, s)
      if parent != nil and sfMainModule in parent.module.flags:
        # but we'll only worry about it for MainModule
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
        break

    # critically, we must check for conflicts at the source module
    # in the event a global symbol is actually foreign to `p`
    # NOTE: constants are effectively global
    if sfGlobal in s.flags or s.kind == skConst:
      var parent = findPendingModule(m, s)
      if parent != nil:   # javascript can yield nil here
        when parent is BModule:
          when p is BModule:
            # is it (not) foreign?  terribly expensive, i know.
            if parent.cfilename.string == m.cfilename.string:
              break
          # use or set the existing foreign counter for the key
          (name, counter) = getSetConflict(parent, s)
          # use or set the existing foreign counter for the name
          next = mgetOrPut(parent.sigConflicts, name, counter + 1)
          break

  # only write mangled names for c codegen
  when m is BModule:
    # and only if they aren't temporaries
    if s.kind != skTemp:
      # cache the symbol for write at file close
      writeMangledName(m.ndi, s, m.config)

  # if the counter hasn't been set from a foreign or cached symbol,
  if counter == -1:
    # set it using the local conflicts table
    counter = getOrSet(p.sigConflicts, name, conflictKey(s))
  else:
    # else, stuff it into the local table with the discovered counter
    p.sigConflicts[key] = counter

    # set the next value to the larger of the local and remote values
    p.sigConflicts[name] = max(counter + 1,
                               getOrDefault(p.sigConflicts, name, 1))

  result = (name: name, counter: counter)

proc idOrSig*(m: ModuleOrProc; s: PSym): Rope =
  ## produce a unique identity-or-signature for the given module and symbol
  let conflict = getSetConflict(m, s)
  result = conflict.name.rope
  result.maybeAppendCounter conflict.counter
  when nimDebugMangle != "":
    if startsWith($result, nimDebugMangle):
      debug s
      when m is BModule:
        result = "/*" & $conflictKey(s) & "*/" & result
        debug m.cfilename
        debug "module $4 >> $1 .. $2 -> $3" %
          [ $conflictKey(s), s.name.s, $result, $conflictKey(m.module) ]
      elif m is BProc:
        result = "/*" & $conflictKey(s) & "*/" & result
        debug "  proc $4 >> $1 .. $2 -> $3" %
          [ $conflictKey(s), s.name.s, $result,
           if m.prc != nil: $conflictKey(m.prc) else: "(nil)" ]

proc getTypeName*(p: ModuleOrProc; typ: PType): Rope =
  ## produce a useful name for the given type, obvs
  let m = getem()
  var key = $conflictKey(typ)
  block found:
    # try to find the actual type
    var t = typ
    while true:
      # use an immutable symbol name if we find one
      if t.sym.hasImmutableName:
        # the symbol might need mangling, first
        result = mangleName(p, t.sym)
        break found
      elif t.kind in irrelevantForBackend:
        t = t.lastSon    # continue into more precise types
      else:
        break            # this looks like a good place to stop

    assert t != nil
    result = typeName(p, t).rope
    let counter = getOrSet(p.sigConflicts, $result, conflictKey(t))
    result.maybeAppendCounter counter

    when nimDebugMangle != "":
      if startsWith($result, nimDebugMangle):
        debug typ
        result.add "/*" & $key & "*/"

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
  assert result.endsWith("_")
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

proc mangleName*(p: ModuleOrProc; s: PSym): Rope =
  ## Mangle the symbol name and set a new location rope for it, returning
  ## same.  Has no effect if the symbol already has a location rope.
  if s.loc.r == nil:
    when p is BModule:
      # skParam is valid for global object fields with proc types
      #assert s.kind notin {skParam, skResult}
      assert s.kind notin {skResult}
    when p is BProc:
      assert s.kind notin {skModule, skPackage}
    s.loc.r = idOrSig(p, s)
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
    if s.kind != skResult:
      s.loc.r = nil              # from the parent module as we move it local
      s.loc.r = mangleName(p, s) # and force the new location like a punk
    else:
      s.loc.r = ~"result"        # or just set it to result if it's skResult
  if s.loc.r == nil:
    internalError(p.config, s.info, "assignParam")

proc mangleParamName*(p: BProc; s: PSym): Rope =
  ## mangle a param name when we actually have the target proc
  result = mangleName(p, s)
  if result == nil:
    internalError(p.config, s.info, "mangleParamName")

proc mangleParamName*(m: BModule; s: PSym): Rope =
  ## we should be okay with just a simple mangle here for prototype
  ## purposes; the real meat happens in assignParam later...
  if s.loc.r == nil:
    s.loc.r = mangle(m, s).rope
  result = s.loc.r
  if result == nil:
    internalError(m.config, s.info, "mangleParamName")
