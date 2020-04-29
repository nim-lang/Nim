import

  options, ast, astalgo, msgs, idents, renderer, magicsys, vmdef,
  modulegraphs, lineinfos, somenode

import

  std / intsets, sets

type
  TOptionEntry* = object      # entries to put on a stack for pragma parsing
    options*: TOptions
    defaultCC*: TCallingConvention
    dynlib*: PLib
    notes*: TNoteKinds
    features*: set[Feature]
    otherPragmas*: PNode      # every pragma can be pushed
    warningAsErrors*: TNoteKinds

  POptionEntry* = ref TOptionEntry
  PProcCon* = ref TProcCon
  TProcCon* = object          # procedure context; also used for top-level
                              # statements
    owner*: PSym              # the symbol this context belongs to
    resultSym*: PSym          # the result symbol (if we are in a proc)
    selfSym*: PSym            # the 'self' symbol (if available)
    nestedLoopCounter*: int   # whether we are in a loop or not
    nestedBlockCounter*: int  # whether we are in a block or not
    inTryStmt*: int           # whether we are in a try statement; works also
                              # in standalone ``except`` and ``finally``
    next*: PProcCon           # used for stacking procedure contexts
    wasForwarded*: bool       # whether the current proc has a separate header
    mappingExists*: bool
    mapping*: TIdTable
    caseContext*: seq[tuple[n: PNode, idx: int]]

  TMatchedConcept* = object
    candidateType*: PType
    prev*: ptr TMatchedConcept
    depth*: int

  TInstantiationPair* = object
    genericSym*: PSym
    inst*: PInstantiation

  TExprFlag* = enum
    efLValue, efWantIterator, efInTypeof,
    efNeedStatic,
      # Use this in contexts where a static value is mandatory
    efPreferStatic,
      # Use this in contexts where a static value could bring more
      # information, but it's not strictly mandatory. This may become
      # the default with implicit statics in the future.
    efPreferNilResult,
      # Use this if you want a certain result (e.g. static value),
      # but you don't want to trigger a hard error. For example,
      # you may be in position to supply a better error message
      # to the user.
    efWantStmt, efAllowStmt, efDetermineType, efExplain,
    efAllowDestructor, efWantValue, efOperand, efNoSemCheck,
    efNoEvaluateGeneric, efInCall, efFromHlo, efNoSem2Check,
    efNoUndeclared
      # Use this if undeclared identifiers should not raise an error during
      # overload resolution.

  TExprFlags* = set[TExprFlag]

  PContext* = ref TContext
  TContext* = object of TPassContext # a context represents the module
                                     # that is currently being compiled
    enforceVoidContext*: PType
    module*: PSym              # the module sym belonging to the context
    currentScope*: PScope      # current scope
    importTable*: PScope       # scope for all imported symbols
    topLevelScope*: PScope     # scope for all top-level symbols
    p*: PProcCon               # procedure context
    matchedConcept*: ptr TMatchedConcept # the current concept being matched
    friendModules*: seq[PSym]  # friend modules; may access private data;
                               # this is used so that generic instantiations
                               # can access private object fields
    instCounter*: int          # to prevent endless instantiations

    ambiguousSymbols*: IntSet  # ids of all ambiguous symbols (cannot
                               # store this info in the syms themselves!)
    inGenericContext*: int     # > 0 if we are in a generic type
    inStaticContext*: int      # > 0 if we are inside a static: block
    inUnrolledContext*: int    # > 0 if we are unrolling a loop
    compilesContextId*: int    # > 0 if we are in a ``compiles`` magic
    compilesContextIdGenerator*: int
    inGenericInst*: int        # > 0 if we are instantiating a generic
    converters*: seq[PSym]
    patterns*: seq[PSym]       # sequence of pattern matchers
    optionStack*: seq[POptionEntry]
    symMapping*: TIdTable      # every gensym'ed symbol needs to be mapped
                               # to some new symbol in a generic instantiation
    libs*: seq[PLib]           # all libs used by this module
    semConstExpr*: proc (c: PContext, n: PNode): PNode {.nimcall.} # for the pragmas
    semExpr*: proc (c: PContext, n: PNode, flags: TExprFlags = {}): PNode {.nimcall.}
    semTryExpr*: proc (c: PContext, n: PNode, flags: TExprFlags = {}): PNode {.nimcall.}
    semTryConstExpr*: proc (c: PContext, n: PNode): PNode {.nimcall.}
    computeRequiresInit*: proc (c: PContext, t: PType): bool {.nimcall.}
    hasUnresolvedArgs*: proc (c: PContext, n: PNode): bool

    semOperand*: proc (c: PContext, n: PNode, flags: TExprFlags = {}): PNode {.nimcall.}
    semConstBoolExpr*: proc (c: PContext, n: PNode): PNode {.nimcall.} # XXX bite the bullet
    semOverloadedCall*: proc (c: PContext, n, nOrig: PNode,
                              filter: TSymKinds, flags: TExprFlags): PNode {.nimcall.}
    semTypeNode*: proc(c: PContext, n: PNode, prev: PType): PType {.nimcall.}
    semInferredLambda*: proc(c: PContext, pt: TIdTable, n: PNode): PNode
    semGenerateInstance*: proc (c: PContext, fn: PSym, pt: TIdTable,
                                info: TLineInfo): PSym
    includedFiles*: IntSet     # used to detect recursive include files
    pureEnumFields*: TStrTable # pure enum fields that can be used unambiguously
    userPragmas*: TStrTable
    evalContext*: PEvalContext
    unknownIdents*: IntSet     # ids of all unknown identifiers to prevent
                               # naming it multiple times
    generics*: seq[TInstantiationPair] # pending list of instantiated generics to compile
    topStmts*: int # counts the number of encountered top level statements
    lastGenericIdx*: int      # used for the generics stack
    hloLoopDetector*: int     # used to prevent endless loops in the HLO
    inParallelStmt*: int
    instTypeBoundOp*: proc (c: PContext; dc: PSym; t: PType; info: TLineInfo;
                            op: TTypeAttachedOp; col: int): PSym {.nimcall.}
    selfName*: PIdent
    cache*: IdentCache
    graph*: ModuleGraph
    signatures*: TStrTable
    recursiveDep*: string
    suggestionsMade*: bool
    features*: set[Feature]
    inTypeContext*: int
    typesWithOps*: seq[(PType, PType)] #\
      # We need to instantiate the type bound ops lazily after
      # the generic type has been constructed completely. See
      # tests/destructor/topttree.nim for an example that
      # would otherwise fail.
    unusedImports*: seq[(PSym, TLineInfo)]
    exportIndirections*: HashSet[(int, int)]
    icSealed: bool          # IC: the tree is sealed and immutable
    icCache: NodeDeque      # IC: nodes that may be cached
