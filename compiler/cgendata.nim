#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains the data structures for the C code generation phase.

import

  ast, ropes, options, intsets, tables, ndi, lineinfos, sets, pathutils,
  modulegraphs, astalgo, hashes, msgs

type
  TLabel* = Rope              # for the C generator a label is just a rope
  TCFileSection* = enum       # the sections a generated C file consists of
    cfsMergeInfo,             # section containing merge information
    cfsHeaders,               # section for C include file headers
    cfsFrameDefines           # section for nim frame macros
    cfsForwardTypes,          # section for C forward typedefs
    cfsTypes,                 # section for C typedefs
    cfsSeqTypes,              # section for sequence types only
                              # this is needed for strange type generation
                              # reasons
    cfsFieldInfo,             # section for field information
    cfsTypeInfo,              # section for type information (ag ABI checks)
    cfsProcHeaders,           # section for C procs prototypes
    cfsData,                  # section for C constant data
    cfsVars,                  # section for C variable declarations
    cfsProcs,                 # section for C procs that are not inline
    cfsInitProc,              # section for the C init proc
    cfsDatInitProc,           # section for the C datInit proc
    cfsTypeInit1,             # section 1 for declarations of type information
    cfsTypeInit2,             # section 2 for init of type information
    cfsTypeInit3,             # section 3 for init of type information
    cfsDebugInit,             # section for init of debug information
    cfsDynLibInit,            # section for init of dynamic library binding
    cfsDynLibDeinit           # section for deinitialization of dynamic
                              # libraries
  TCTypeKind* = enum          # describes the type kind of a C type
    ctVoid, ctChar, ctBool,
    ctInt, ctInt8, ctInt16, ctInt32, ctInt64,
    ctFloat, ctFloat32, ctFloat64, ctFloat128,
    ctUInt, ctUInt8, ctUInt16, ctUInt32, ctUInt64,
    ctArray, ctPtrToArray, ctStruct, ctPtr, ctNimStr, ctNimSeq, ctProc,
    ctCString
  TCFileSections* = array[TCFileSection, Rope] # represents a generated C file
  TCProcSection* = enum       # the sections a generated C proc consists of
    cpsLocals,                # section of local variables for C proc
    cpsInit,                  # section for init of variables for C proc
    cpsStmts                  # section of local statements for C proc
  TCProcSections* = array[TCProcSection, Rope] # represents a generated C proc
  BModule* = ref TCGen
  BProc* = ref TCProc
  TBlock* = object
    id*: int                  # the ID of the label; positive means that it
    label*: Rope              # generated text for the label
                              # nil if label is not used
    sections*: TCProcSections # the code belonging
    isLoop*: bool             # whether block is a loop
    nestedTryStmts*: int16    # how many try statements is it nested into
    nestedExceptStmts*: int16 # how many except statements is it nested into
    frameLen*: int16

  TCProcFlag* = enum
    beforeRetNeeded,
    threadVarAccessed,
    hasCurFramePointer,
    noSafePoints,
    nimErrorFlagAccessed,
    nimErrorFlagDeclared,
    nimErrorFlagDisabled

  TCProc = object             # represents C proc that is currently generated
    prc*: PSym                # the Nim proc that this C proc belongs to
    flags*: set[TCProcFlag]
    lastLineInfo*: TLineInfo  # to avoid generating excessive 'nimln' statements
    currLineInfo*: TLineInfo  # AST codegen will make this superfluous
    nestedTryStmts*: seq[tuple[fin: PNode, inExcept: bool, label: Natural]]
                              # in how many nested try statements we are
                              # (the vars must be volatile then)
                              # bool is true when are in the except part of a try block
    finallySafePoints*: seq[Rope]  # For correctly cleaning up exceptions when
                                   # using return in finally statements
    labels*: Natural          # for generating unique labels in the C proc
    blocks*: seq[TBlock]      # nested blocks
    breakIdx*: int            # the block that will be exited
                              # with a regular break
    options*: TOptions        # options that should be used for code
                              # generation; this is the same as prc.options
                              # unless prc == nil
    module*: BModule          # used to prevent excessive parameter passing
    withinLoop*: int          # > 0 if we are within a loop
    splitDecls*: int          # > 0 if we are in some context for C++ that
                              # requires 'T x = T()' to become 'T x; x = T()'
                              # (yes, C++ is weird like that)
    withinTryWithExcept*: int # required for goto based exception handling
    withinBlockLeaveActions*: int # complex to explain
    sigConflicts*: ConflictsTable

  TTypeSeq* = seq[PType]
  TypeCache* = Table[SigHash, Rope]
  TypeCacheWithOwner* = Table[SigHash, tuple[str: Rope, owner: PSym]]

  CodegenFlag* = enum
    preventStackTrace,  # true if stack traces need to be prevented
    usesThreadVars,     # true if the module uses a thread var
    frameDeclared,      # hack for ROD support so that we don't declare
                        # a frame var twice in an init proc
    isHeaderFile,       # C source file is the header file
    includesStringh,    # C source file already includes ``<string.h>``
    objHasKidsValid     # whether we can rely on tfObjHasKids


  BModuleList* = ref object of RootObj
    mainModProcs*, mainModInit*, otherModsInit*, mainDatInit*: Rope
    mapping*: Rope             # the generated mapping file (if requested)
    modules*: seq[BModule]     # list of all compiled modules
    modulesClosed*: seq[BModule] # list of the same compiled modules, but in the order they were closed
    forwardedProcs*: seq[PSym] # proc:s that did not yet have a body
    generatedHeader*: BModule
    typeInfoMarker*: TypeCacheWithOwner
    typeInfoMarkerV2*: TypeCacheWithOwner
    config*: ConfigRef
    graph*: ModuleGraph
    strVersion*, seqVersion*: int # version of the string/seq implementation to use

    nimtv*: Rope            # Nim thread vars; the struct body
    nimtvDeps*: seq[PType]  # type deps: every module needs whole struct
    nimtvDeclared*: IntSet  # so that every var/field exists only once
                            # in the struct
                            # 'nimtv' is incredibly hard to modularize! Best
                            # effort is to store all thread vars in a ROD
                            # section and with their type deps and load them
                            # unconditionally...
                            # nimtvDeps is VERY hard to cache because it's
                            # not a list of IDs nor can it be made to be one.
    nameCache: MangleCache

  ConflictsTable* = Table[string, int]
  ConflictKey* = int

  # this mangling stuff is intentionally verbose; err on side of caution!
  #
  BName* = distinct string              # a mangled name used in backend
  BNameInput = BName or string or Rope  # you can make a BName from these

  Mangling = object
    key: ConflictKey                         # unique id of type/symbol
    sig: SigHash                             # signature of type/symbol
    name: BName                              # mangled backend name
    module: int                              # source module

  MangleCache = object
    manglings: Table[BName, Mangling]        # link name to debug info
    identities: Table[ConflictKey, BName]    # link unique id to name
    signatures: Table[SigHash, ConflictKey]  # unifies types by sig

  TCGen = object of PPassContext # represents a C source file
    s*: TCFileSections        # sections of the C file
    flags*: set[CodegenFlag]
    module*: PSym
    filename*: AbsoluteFile
    cfilename*: AbsoluteFile  # filename of the module (including path,
                              # without extension)
    tmpBase*: string          # base for temp identifier generation
    typeCache*: TypeCache     # cache the generated types
    typeABICache*: HashSet[SigHash] # cache for ABI checks; reusing typeCache
                              # would be ideal but for some reason enums
                              # don't seem to get cached so it'd generate
                              # 1 ABI check per occurence in code
    forwTypeCache*: TypeCache # cache for forward declarations of types
    declaredThings*: IntSet   # things we have declared in this .c file
    declaredProtos*: IntSet   # prototypes we have declared in this .c file
    headerFiles*: seq[string] # needed headers to include
    typeInfoMarker*: TypeCache # needed for generating type information
    typeInfoMarkerV2*: TypeCache
    initProc*: BProc          # code for init procedure
    preInitProc*: BProc       # code executed before the init proc
    hcrCreateTypeInfosProc*: Rope # type info globals are in here when HCR=on
    inHcrInitGuard*: bool     # We are currently within a HCR reloading guard.
    typeStack*: TTypeSeq      # used for type generation
    dataCache*: TNodeTable
    typeNodes*, nimTypes*: int # used for type info generation
    typeNodesName*, nimTypesName*: Rope # used for type info generation
    labels*: Natural          # for generating unique module-scope names
    extensionLoaders*: array['0'..'9', Rope] # special procs for the
                                             # OpenGL wrapper
    injectStmt*: Rope
    sigConflicts*: ConflictsTable
    g*: BModuleList
    ndi*: NdiFile

const
  irrelevantForBackend* = {tyGenericBody, tyGenericInst, tyOwned,
                           tyGenericInvocation, tyDistinct, tyRange,
                           tyStatic, tyAlias, tySink, tyInferred}

template config*(m: BModule): ConfigRef = m.g.config
template config*(p: BProc): ConfigRef = p.module.g.config

proc includeHeader*(this: BModule; header: string) =
  if not this.headerFiles.contains header:
    this.headerFiles.add header

proc s*(p: BProc, s: TCProcSection): var Rope {.inline.} =
  # section in the current block
  result = p.blocks[^1].sections[s]

proc procSec*(p: BProc, s: TCProcSection): var Rope {.inline.} =
  # top level proc sections
  result = p.blocks[0].sections[s]

proc newProc*(prc: PSym, module: BModule): BProc =
  new(result)
  result.prc = prc
  result.module = module
  result.options = if prc != nil: prc.options
                   else: module.config.options
  newSeq(result.blocks, 1)
  result.nestedTryStmts = @[]
  result.finallySafePoints = @[]
  result.sigConflicts = initTable[string, int]()

template getem*() =
  # get a BModule when we might only have a BProc
  when p is BProc:
    p.module
  else:
    p

proc findPendingModule*(g: BModuleList; s: PSym): BModule =
  ## Find the backend module to which a symbol belongs.
  result = g.modules[getModule(s).position]

proc findPendingModule*(m: BModule; s: PSym): BModule =
  ## Find the backend module to which a symbol belongs.
  if s == nil:
    result = m
  else:
    result = findPendingModule(m.g, s)

proc findPendingModule*(m: BModule; t: PType): BModule =
  ## Find the backend module to which a type belongs.
  if t.owner == nil:
    result = findPendingModule(m.g, t.sym)
  else:
    result = findPendingModule(m.g, t.owner)

# get a ConflictKey from a PSym or PType
template conflictKey*(s: PSym): ConflictKey = ConflictKey s.id
template conflictKey*(s: PType): ConflictKey = ConflictKey s.uniqueId

proc initMangleCache(): MangleCache = discard

proc hash*(s: BName): Hash {.borrow.}
proc `==`*(a, b: BName): bool {.borrow.}
proc `<`*(a, b: BName): bool {.borrow.}
proc `$`*(s: BName): string {.borrow.}

proc `$`(m: Mangling): string =
  for k, v in fieldPairs(m):
    result.add "\t" & k & ": " & $v & "\n"

proc add*(s: var BName; x: BNameInput) =
  # sure, you can mutate it, but we'll make it hard for you
  (string s).add "/*" & $x & "*/"

proc `&`*(s: BName; x: BNameInput): BName =
  result = s
  result.add x

converter toString*(s: BName): string = s.string
converter toRope*(s: BName): Rope = rope(s.string)

proc newMangling(m: BModule; p: PSym or PType; name: BNameInput;
                 sig: SigHash): Mangling =
  when name isnot BName:
    if name.len == 0:
      internalError(m.config, "empty identifier names are not supported")
    let name =
      when name is Rope:
        BName $name
      else:
        BName name
  result = Mangling(key: conflictKey(p), sig: sig, name: name,
                    module: m.module.id)

proc setName*(g: BModuleList; m: BModule; p: PSym or PType;
              name: BNameInput; sig: SigHash): BName =
  let man = newMangling(m, p, name, sig)
  result = man.name

  when p is PType:         # cache type signature if necessary
    discard hasKeyOrPut(g.nameCache.signatures, man.sig, man.key)

  when defined(release):
    g.nameCache.identities[man.key] = result
    discard hasKeyOrPut(g.nameCache.manglings, result, man)
  else:
    try:
      echo "set key ", man.key, " with sig ", man.sig, " at ", man.name
      assert man.key notin g.nameCache.identities
      g.nameCache.identities[man.key] = result
      if hasKeyOrPut(g.nameCache.manglings, result, man):
        assert g.nameCache.manglings[result].key != man.key
    except:
      echo "assertion error for mangling `", name, "`"
      echo "here's the input object:"
      debug p
      echo "here's the current mangling:"
      echo man
      if man.key in g.nameCache.identities:
        echo "key already cached as `", g.nameCache.identities[man.key], "`"
        echo "here's the previous mangling:"
        echo g.nameCache.manglings[g.nameCache.identities[man.key]]
      if man.name in g.nameCache.manglings:
        echo "name already cached; here's the previous mangling:"
        echo g.nameCache.manglings[man.name]
      raise

proc setName*(g: BModuleList; p: PSym or PType; name: BNameInput) =
  let sig = when p is PSym: sigHash(p) else: hashTypeDef(p)
  assert p.owner != nil
  let m = findPendingModule(g, p.owner)
  g.setName(m, p, name, sig)

proc hasName*(g: BModuleList; key: ConflictKey; sig: SigHash): bool =
  result = key in g.nameCache.identities
  when not defined(release):
    if result:
      try:
        let man = g.nameCache.manglings[g.nameCache.identities[key]]
        # we decided to allow multiple keys to share the same mangle
        # as long as they have the same signature or somethin'
        #assert man.key == key
        assert man.sig == sig
        assert man.name == g.nameCache.identities[key]
      except:
        echo "looking for key ", key, " with sig ", sig
        echo "which has name ", g.nameCache.identities[key]
        if g.nameCache.identities[key] in g.nameCache.manglings:
          echo "the existing mangle is:"
          echo g.nameCache.manglings[g.nameCache.identities[key]]
        else:
          echo "there is no existing mangle"
        raise

proc unaliasTypeBySignature*(g: BModuleList;
                             key: ConflictKey;
                             sig: SigHash): ConflictKey =
  ## used by the mangler to avoid out-of-order name
  ## introductions for sig-equal types that vary in identity
  ## and do not share source modules...  fun, right?
  result = getOrDefault(g.nameCache.signatures, sig, key)

proc hackIfThisNameIsAlreadyInUseInTheGlobalRegistry*(g: BModuleList;
                                                      name: BNameInput;
                                                      key: ConflictKey;
                                                      sig: SigHash): bool
  {.deprecated: "hack".} =
  ## XXX: remove me; used by the mangler to skip global names
  ##      previously defined in unrelated modules...
  let name = BName $name
  if key in g.nameCache.identities:
    # if we have a key, then the name is a conflict if it wasn't used prior
    result = g.nameCache.identities[key] != name
  else:
    # basically, defer to later tests
    result = true
  # the name is in use if there's already a mangle for it
  result = result and name in g.nameCache.manglings
  # the name is in use if the signatures don't match
  result = result and g.nameCache.manglings[name].sig != sig

proc name*(g: BModuleList; key: ConflictKey; sig: SigHash): BName =
  # let it raise a KeyError as necessary...
  result = g.nameCache.identities[key]
  when not defined(release):
    echo "get key ", key, " with sig ", sig, " at ", result
    # make sure our expectations match reality
    let man = g.nameCache.manglings[result]
    assert sig == man.sig
    assert result == man.name
    # we decided to allow multiple keys to share the same mangle
    # as long as they have the same signature or somethin'
    #assert man.key == key

proc newModuleList*(g: ModuleGraph): BModuleList =
  BModuleList(typeInfoMarker: initTable[SigHash, tuple[str: Rope, owner: PSym]](),
    config: g.config, graph: g, nimtvDeclared: initIntSet(),
    nameCache: initMangleCache())

iterator cgenModules*(g: BModuleList): BModule =
  for m in g.modulesClosed:
    # iterate modules in the order they were closed
    yield m

when not defined(release):
  proc `[]=`*(tc: var TypeCache; sig: SigHash; name: Rope) =
    ## make sure we aren't mutating the typecache incorrectly
    if sig in tc:
      let old = tc[sig]
      assert $name == $old, "typecache mutation: " & $name & " -> " & $old
      assert false, "gratuitous typecache set"
    tables.`[]=`(tc, sig, name)

proc cacheGetType*(tab: TypeCache; sig: SigHash): Rope =
  # returns nil if we need to declare this type
  # since types are now unique via the ``getUniqueType`` mechanism, this slow
  # linear search is not necessary anymore:
  result = tab.getOrDefault(sig)
