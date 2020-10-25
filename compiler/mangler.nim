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
  "someMangledName" -> the output of mangle() on a symbol or
  "someMangledName" -> the output of getTypeName() on a type or
  "######" -> a series of digits representing a unique symbol or type id

The values have different meanings depending upon the form of the key:
  "someMangledName" -> the value represents the next available counter
  "######" -> the value represents the counter associated with the id

The counter is used to keep track of the order of symbol additions to the
conflict table; they are increasing but not guaranteed to be sequential.

]##

import # compiler imports

    ast, cgendata, modulegraphs, ropes, ccgutils, ndi, msgs,
    idents, options, wordrecg, astalgo, treetab, sighashes

import # stdlib imports

  std / [ strutils, tables, sets ]

const
  inspect = "foo_int"
  debugMangle = true and not defined(release)
  symbolicTypes =
    when true:
      {tyObject, tyEnum} # obey the boss
    else:
      {TTypeKind.low .. TTypeKind.high} - {tyString}

  # these may be shorted to the first three characters following `ty`
  # as opposed to perhaps being stripped of vowels, etc.
  threeLetterShorties = {tyOrdinal, tySequence, tyObject, tyTuple, tyArray,
                         tyVar, tyPtr, tyString, tySet, tyRef, tyTypeDesc}
  # these are types that we ignore entirely when mangling
  irrelevantForNaming = irrelevantForBackend + {tyVar} - {tyRange}
  # these types may prefix the types they wrap, eg. `seqStr` or `setInt`
  abbrevTypeArg = {tySet, tySequence, tyTypeDesc, tyArray, tyRange}
  # these types get unwrapped and discarded from mangling
  unwrapTypeArg = irrelevantForNaming - {tyRange} + {tyRef, tyPtr,
                                         tyUserTypeClass, tyUserTypeClassInst}
  unIdentity = ItemId(module: -1, item: -1)

type
  ModuleOrProc* = BProc or BModule

template config(): ConfigRef = cache.modules.config
template add_and(s: typed; chs: string) = s.add "_"; s.add chs
template add_and(s: typed; key: ConflictKey) = s.add_and $key.item

using
  g: ModuleGraph

# useful for debugging
template conflictKey(s: BModule): ConflictKey = conflictKey(s.module)
template conflictKey(s: BProc): ConflictKey =
  if s.prc == nil: unIdentity else: conflictKey(s.prc)

template mangle*(p: ModuleOrProc; t: PType): string = $getTypeName(p, t)
proc mangle*(p: ModuleOrProc; s: PSym): string
proc mangleName*(p: ModuleOrProc; s: PSym): Rope
proc typeName(p: ModuleOrProc; typ: PType; shorten = false): string

proc `==`(m, p: BModule): bool =
  if not p.isNil and not m.isNil:
    result = p.module.id == m.module.id
    # this is needed to disambiguate system modules
    result = result and p.cfilename.string == m.cfilename.string

proc getSomeNameForModule*(m: PSym): string =
  ## Produce a name for the given module symbol.
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

template maybeAddCounter(result: typed; p: PType or PSym; count: int) =
  if count > 0:
    if not p.hasImmutableName:
      add_and result, $count

proc getOrSet(p: ModuleOrProc; name: string; key: ConflictKey): int =
  ## Add/get a mangled name from the scope's conflicts table and return
  ## the number of conflicts for that name at the time of its insertion.
  template conflicts(): var ConflictsTable = p.sigConflicts

  result = conflicts[key]
  if result == -1:
    when debugMangle:
      if startsWith(name, inspect):
        echo "getorset on ", $typeof(p), " ", conflictKey(p), " addr ", cast[uint](p), " table ", cast[uint](addr conflicts)
        when p is BModule:
          echo "getorset (module) ", p.cfilename.string
          echo "getorset (module) ", p.module.flags
        else:
          echo "getorset (proc) ", p.prc.name.s

    # start counting at zero so we can omit an initial append
    result = conflicts[name]
    # set the value for the name to indicate the NEXT available counter
    conflicts[name] = result + 1
    # cache the association between key and result
    conflicts[key] = result

    when debugMangle:
      if startsWith(name, inspect):
        echo "getorset at ", conflictKey(p), " for ", name, " with key ", key, " is ", result

  else:
    # set the value for the name to indicate the NEXT available counter
    # (this will ignore lower values)
    conflicts[name] = result + 1
    when debugMangle:
      echo "getorset has ", key, " has ", result, " for ", name
      if result >= conflicts[name]:
        echo "module ", conflictKey(p), " and name ", name
        internalError(p.config,
          "clash count unexpectedly low; result " & $result &
          "; table is " & $conflicts[name])

template purgeConflict(m: ModuleOrProc; key: ConflictKey) =
  ## Remove a cached symbol or type identity from a conflicts table.
  del(m.sigConflicts, key)

proc purgeConflict*(m: ModuleOrProc; s: PSym or PType) =
  ## Remove a cached symbol or type from a conflicts table.
  purgeConflict(m, conflictKey(s))

proc hackAroundGlobalRegistryCollisions(p: ModuleOrProc;
                                        s: PType or PSym;
                                        sig: SigHash;
                                        name: string;
                                        counter: var int): BName =
  let m = getem()
  var key = conflictKey(s)
  var broken = false
  when s is PType:
    broken = key in m.sigConflicts
    # if we already have this key cached, then we'll use the original key
    # so that we don't confuse our local cache in the getOrSet operation
    key = unaliasTypeBySignature(m.g, key, sig)
    when debugMangle:
      if conflictKey(s) != key:
        echo "unaliased ", name, " from ", conflictKey(s), " to ", $key,
          " for sig ", $sig

  if s.hasImmutableName:
    # immutable names don't even hit the global registry
    counter = getOrSet(m, name, key)
    result = BName name
  elif m.g.hasName(key, sig):
    # here we need to handle a previously-cached name for this key/sig
    counter = m.g.retrieveCounter(key, sig)
    while true:
      let current = getOrSet(m, name, key)
      if counter == current:
        break
      elif counter > current:
        purgeConflict(m, key)
      elif counter < current:
        m.g.bumpCounter(key, sig, current)
        break
    result = m.g.name(key, sig)
  else:
    # in this scenario, there's nothing cached for this key/sig
    while true:
      counter = getOrSet(m, name, key)
      var aNameForTesting = name
      aNameForTesting.maybeAddCounter(s, counter)
      if counter > 0:
        assert aNameForTesting != name
      if hackIfThisNameIsAlreadyInUseInTheGlobalRegistry(m.g, # KILL ME NOW
                                                         aNameForTesting,
                                                         key, sig):
        when debugMangle:
          echo "purge $1 for $2 name $3; counter $4" %
            [ $conflictKey(s), $key, aNameForTesting, $counter ]

        # if we already have a counter for this name and yet
        # it stands in conflict against the global registry,
        # then we've made a very serious error!
        if broken:
          internalError(m.config, "attempt to recount " & name)

        # we need to purge `key`, not conflictKey(s)
        purgeConflict(m, key)
      else:
        result = BName aNameForTesting
        break

  when debugMangle:
    if counter != 0:
      echo "the collision hack chose counter ", counter, " for ", name
    echo "collision hack yielding ", result

proc floatConflict(p: ModuleOrProc; s: PType or PSym; name: string): BName =
  ## Mix a local name into any parent scopes of `s`.
  var m = getem()
  m = findPendingModule(m, s)   # redirect to the source module for `s`

  var counter = -1
  let sig = conflictSig(s)
  result = hackAroundGlobalRegistryCollisions(m, s, sig, name, counter)

  # copy the cache to the local module or proc if necessary
  if (when p is BProc: true else: m != p):
    p.sigConflicts[s] = counter                 # set the local counter
    p.sigConflicts[name] = m.sigConflicts[name] # set the local name

  result = m.g.setName(m, s, result, sig)

proc shouldAddModuleName(s: PSym): bool =
  ## Are we going to apply top-level mangling semantics?
  assert not s.hasImmutableName
  case s.kind
  of skParam, skResult, skModule, skPackage, skTemp:
    result = false
  of skConst:
    result = true        # NOTE: constants are effectively global
  of skProc:
    result = true        # for linking reasons demonstrable in megatest
  else:
    if s.owner != nil and sfSystemModule in s.owner.flags:
      result = false     # omit "system" in the interests of brevity
    elif s.owner == nil or s.owner.kind in {skModule, skPackage}:
      result = true      # the symbol is top-level; add the module name
    elif {sfGlobal, sfGeneratedOp} * s.flags != {}:
      result = true      # the symbol is top-level; add the module name
    elif s.kind == skForVar:
      # forvars get special handling due to the fact that they
      # can, in rare and stupid cases, be globals...
      result = false
    elif sfExported in s.flags:
      result = true      # exports get their source module appended

proc shortKind(k: TTypeKind): string =
  ## truncate longer type names
  const vowels = {'a','e','i','o','u'}
  result = toLowerAscii($k)
  removePrefix(result, "ty")
  result = case k
  of threeLetterShorties:       # handle der usual suspects especialment
    result[0 .. 2]
  elif len(result) > 4:         # elide vowels to shrink it
    if result[0] in vowels:
      # if it starts with a vowel, keep that letter; think `Opnrry`, `Unt32`
      $result[0] & split(result[1..^1], vowels).join("")
    else:
      split(result, vowels).join("")
  else: result

proc naiveTypeName(p: ModuleOrProc; typ: PType; shorten = false): string =
  ## compose a type name for a type that has an unusable symbol
  var typ = typ.skipTypes(irrelevantForNaming)
  result = case typ.kind
  of abbrevTypeArg:
    # set[Enum] -> setEnum for "first word" shortening purposes
    shortKind(typ.kind) & typeName(p, typ.lastSon, shorten).capitalizeAscii
  of unwrapTypeArg:
    # omit this verbosity for now and simply discard the wrapper
    typeName(p, typ.lastSon, shorten = shorten)
  of tyProc, tyTuple:
    # these can figure into the signature though they may not be exported
    # as types, so signature won't match when it comes time to link
    let m = getem()
    let sig = conflictSig(typ)
    var name: BName
    # consult the global cache for a usename name for the type
    if tryGet(m.g, sig, name):
      $name
    # else, maybe we can make a nice name using a referenced symbol
    elif typ.len != 0 and typ.lastSon != nil:
      shortKind(typ.kind) & typeName(p, typ.lastSon, shorten).capitalizeAscii
    # else, compose an ugly name using the signature
    else:
      shortKind(typ.kind) & $conflictSig(typ)
  else:
    shortKind(typ.kind)

proc typeName(p: ModuleOrProc; typ: PType; shorten = false): string =
  ## Come up with a name for any PType; shorten makes it shorter. 😉
  var typ = typ.skipTypes(irrelevantForNaming)
  if typ.sym == nil or typ.kind notin symbolicTypes:
    naiveTypeName(p, typ, shorten = shorten)    # invent our own name...
  elif shorten:
    mangle(p, typ.sym).split("_")[0]            # only use the first "word"
  else:
    mangle(p, typ.sym)                          # use the entire type sym

proc maybeAddProcArgument(p: ModuleOrProc; s: PSym; name: var string): bool =
  ## Should we add the first argument's type to the mangle?  If yes, DO IT.
  result = s.kind in routineKinds
  if result:
    if s.typ != nil:
      if s.typ.sons.len >= 2:
        # avoid including the conflictKey of the 1st param
        name.add_and typeName(p, s.typ.sons[1], shorten = true)

proc mayCollide(p: ModuleOrProc; s: PSym; name: var string): bool =
  ## `true` if the symbol is a source of link collisions; if so,
  ## the name is set to a suitable mangle
  name = ""
  try:
    case s.kind
    of skProc:
      # anonymous procs are special for... reasons
      result = s.name.s == ":anonymous"
      if result:
        name.add "lambda_"
      # var procs are fun; generated proc names, too
      result = result or {sfAddrTaken, sfGenSym} * s.flags != {}
      # closures are great for link collisions
      result = result or tfCapturesEnv in s.typ.flags
    of skIterator:
      result = true
    # a gensym is a good sign that we can encounter a link collision
    elif sfGenSym in s.flags:
      result = true
  finally:
    if result:
      if name.len == 0:
        name = mangle(s.name.s)
      name.add_and conflictKey(s)
      assert not s.hasImmutableName

proc mangle*(p: ModuleOrProc; s: PSym): string =
  ## pending a new backend, all mangles must be done identically
  let m = getem()

  # certain special cases may get a simple mangle early because
  # we must be assured of their consistent clash-free linkage
  if not mayCollide(p, s, result):

    # otherwise, start off by using a name that doesn't suck
    result = mangle(s.name.s)

    # some symbols have flags that preclude further mangling
    if not s.hasImmutableName:

      # add the first argument to procs if possible
      discard maybeAddProcArgument(m, s, result)

      # add the module name if necessary, or if it helps avoid a clash
      if shouldAddModuleName(s) or isNimOrCKeyword(s.name):
        let parent = findPendingModule(m, s)
        if parent != nil:
          result.add_and getSomeNameForModule(parent.module)

      # for c-ish backends, "main" is already defined, of course
      elif s.name.s == "main":
        let parent = findPendingModule(m, s)
        if parent != nil and sfMainModule in parent.module.flags:
          # but we'll only worry about it for MainModule
          result.add_and getSomeNameForModule(parent.module)

      # something like `default` might need this check
      if (unlikely) result in m.config.cppDefines:
        result.add_and conflictKey(s)

  #if getModule(s).id.abs != m.module.id.abs: ...creepy for IC...
  # XXX: we don't do anything special with regard to m.hcrOn
  assert result.len > 0

proc atModuleScope(p: ModuleOrProc; s: PSym): bool =
  ## `true` if the symbol is presumed to be in module-level scope
  ## for the purposes of conflict detection
  const
    globalish = {sfImportc, sfGlobal, sfGeneratedOp, sfExportc, sfExported}

  # NOTE: constants and types and procs are effectively global
  result = s.kind in {skConst, skType, skProc}
  # anything global or otherwise exported or imported is at module scope
  result = result or globalish * s.flags != {}

  when p is BProc:
    # if it's nominally proc but has no proc symbol, then we'll use
    # the module scope for conflict resolution; this solves a fun
    # corner-case where we have a toplevel forVar in an inline iterator
    result = result or p.prc.isNil

proc atModuleScope(p: ModuleOrProc; t: PType): bool =
  ## `true` if the type is presumed to be in module-level scope
  ## for the purposes of conflict detection
  result = true # t.sym == nil or atModuleScope(p, t.sym)

proc getSetConflict(p: ModuleOrProc; s: PSym): BName =
  ## Produce an appropriate name for a symbol, and the instances of its
  ## occurence, which may have been incremented for this instance.
  let m = getem()
  let key = conflictKey(s)
  let sig = conflictSig(s)

  # for now, use the global registry everywhere if possible
  if tryGet(m.g, key, sig, result):
    return

  # we often mangle it anew, which is kinda sad
  var name = mangle(p, s)

  block:
    when p is BModule:
      if m.g.config.symbolFiles != disabledSf:
        # we can use the IC cache to determine the right name and counter
        # for this symbol, but only for module-level manglings
        discard tryGet(m.g, key, sig, result)
        break

    if atModuleScope(p, s):
      # critically, we must check for conflicts at the source module
      # in the event a global symbol is actually foreign to `p`
      result = floatConflict(p, s, name)
      if not m.g.hasName(key, sig):
        result = m.g.setName(m, s, result, sig)
      break

    # if the result wasn't set from a foreign or cached symbol,
    # set it using the local conflicts table
    var r = name
    r.maybeAddCounter(s, getOrSet(p, name, key))
    result = BName r

  # only write mangled names for c codegen
  when m is BModule:
    # and only if they aren't temporaries
    if s.kind != skTemp:
      # cache the symbol for write at file close
      writeMangledName(m.ndi, s, m.config)

proc idOrSig*(p: ModuleOrProc; s: PSym): Rope =
  ## Provide the location rope for symbol `s` as used in module|proc `p`.
  when debugMangle:
    if s.name.s == inspect:
      echo "p is module ", p is BModule
      echo "p key ", conflictKey(p)

  result = Rope getSetConflict(p, s)
  when debugMangle:
    if startsWith($result, inspect):
      debug s
      when p is BModule:
        result.add "/*" & $conflictKey(s) & "*/"
        debug p.cfilename.string
        debug "module $4 >> $1 .. $2 -> $3" %
          [ $conflictKey(s), s.name.s, $result, $conflictKey(p.module) ]
      elif p is BProc:
        result.add "/*" & $conflictKey(s) & "*/"
        debug "  proc $4 >> $1 .. $2 -> $3" %
          [ $conflictKey(s), s.name.s, $result,
           if p.prc != nil: $conflictKey(p.prc) else: "(nil)" ]

proc getTypeName*(p: ModuleOrProc; typ: PType; sig: SigHash): BName =
  ## Retrieve (or produce) a useful name for the given type; this is what
  ## codegen uses exclusively.
  let m = getem()
  var t = typ
  # we don't currently use the proc scope for types; this is just a guard
  # to ensure that we don't do so accidentally
  var p = m

  var name: string
  block found:
    # try to find the actual type
    while true:
      # use an immutable symbol name if we find one
      if t.sym != nil and hasImmutableName(t.sym):
        # the symbol might need mangling, first
        name = $mangleName(p, t.sym)
        break found
      elif t.kind in irrelevantForNaming:
        t = t.lastSon    # continue into more precise types
      else:
        break            # this looks like a good place to stop

    assert t != nil
    name = typeName(p, t)

  # XXX: dogshit ahead
  #
  # this is temporary, but the goal here is to explicitly show
  # the control flow that demonstrates the needed logic for types

  let tsig = conflictSig(t)
  var counter = -1
  var r = hackAroundGlobalRegistryCollisions(m, t, tsig, name, counter)

  block:
    # name is "foo"
    # r is "foo_#"

    if tryGet(m.g, conflictKey(typ), sig, result):
      # found cached name from input type
      break

    if tryGet(m.g, conflictKey(t), tsig, result):
      # found cached name from refined type
      if conflictKey(t) != conflictKey(typ):
        # cache the name for the input type and signature
        discard m.g.setName(m, typ, result, sig)
      break

    assert atModuleScope(p, t), "we're not prepared to scope types"

    # make sure we use the source module for any type requested
    result = floatConflict(p, t, name)

template tempNameForLabel(m: BModule; label: int): string =
  ## create an appropriate temporary name for the given label
  m.tmpBase & $label & "_"

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
  ## Create or retrieve a temporary name for the given node; returns
  ## true if a new name was created and false otherwise.  Appends the
  ## name to the given rope.
  let id = nodeTableTestOrSet(m.dataCache, n, m.labels)
  var name: string
  if id == m.labels:
    name = getTempNameImpl(m, id)
    result = true
  else:
    name = tempNameForLabel(m, id)
    # make sure it's not in the conflicts table under a different id
    assert m.sigConflicts[name] == 1
    # make sure it's in the conflicts table with the NEXT available counter
    m.sigConflicts[name] = 1

  # add or append it to the result
  if r == nil:
    r = name.rope
  else:
    r.add name

proc getTempName*(m: BModule; n: PNode): Rope =
  ## A simpler getTempName that doesn't care where the name comes from.
  discard getTempName(m, n, result)

proc getTempName*(m: BModule): Rope =
  ## A factory for making temporary names for use in the backend; this
  ## mutates the module from which the name originates; this always
  ## creates a new name.
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
    result.add_and "0"

proc mangleRecFieldName*(m: BModule; field: PSym): Rope =
  ## Mangle an object field to ensure it is a valid name in the backend.
  if {sfImportc, sfExportc} * field.flags != {}:
    result = field.loc.r
  else:
    result = mangleField(m, field.name).rope
  if result == nil:
    internalError(m.config, field.info, "mangleRecFieldName")

proc mangleParamName*(m: BModule; s: PSym): Rope =
  ## We should be okay with just a simple mangle here for prototype
  ## purposes; the real meat happens when we're called with BProc...
  if s.loc.r == nil:
    # this is a little subtle; we need a mangle sophisticated enough
    # to rename `default`, and correct enough to match a later mangle,
    # but we don't want to actually getSetConflict() because we don't
    # want param names to be numbered as if they might clash due to
    # the module-level scope of the conflicts table...
    s.loc.r = mangle(m, s).rope
  result = s.loc.r
  if result == nil:
    internalError(m.config, s.info, "mangleParamName")

proc mangleParamName*(p: BProc; s: PSym): Rope =
  ## Push the mangled name into the proc's sigConflicts so that we can
  ## make new local identifiers of the same name without colliding with it.

  # It's likely that the symbol is already in the module scope!
  if s.loc.r == nil or conflictKey(s) notin p.sigConflicts:
    # discard any existing counter for this sym from the module scope
    purgeConflict(p.module, s)
    s.loc.r = nil              # critically, destroy the location
    s.loc.r = mangleName(p, s) # then mangle it using the proc scope
  result = s.loc.r
  if result == nil:
    internalError(p.config, s.info, "mangleParamName")

proc assignParam*(p: BProc, s: PSym; ret: PType) =
  ## i have nothing good to say about this proc
  discard # mangleParamName(p, s)
