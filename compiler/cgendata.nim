#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains the data structures for the C code generation phase.

import 
  ast, astalgo, ropes, passes, options, intsets, lists, platform

type
  TLabel* = PRope             # for the C generator a label is just a rope
  TCFileSection* = enum       # the sections a generated C file consists of
    cfsMergeInfo,             # section containing merge information
    cfsHeaders,               # section for C include file headers
    cfsForwardTypes,          # section for C forward typedefs
    cfsTypes,                 # section for C typedefs
    cfsSeqTypes,              # section for sequence types only
                              # this is needed for strange type generation
                              # reasons
    cfsFieldInfo,             # section for field information
    cfsTypeInfo,              # section for type information
    cfsProcHeaders,           # section for C procs prototypes
    cfsData,                  # section for C constant data
    cfsVars,                  # section for C variable declarations
    cfsProcs,                 # section for C procs that are not inline
    cfsInitProc,              # section for the C init proc
    cfsTypeInit1,             # section 1 for declarations of type information
    cfsTypeInit2,             # section 2 for init of type information
    cfsTypeInit3,             # section 3 for init of type information
    cfsDebugInit,             # section for init of debug information
    cfsDynLibInit,            # section for init of dynamic library binding
    cfsDynLibDeinit           # section for deinitialization of dynamic
                              # libraries
  TCTypeKind* = enum           # describes the type kind of a C type
    ctVoid, ctChar, ctBool, ctUInt, ctUInt8, ctUInt16, ctUInt32, ctUInt64, 
    ctInt, ctInt8, ctInt16, ctInt32, ctInt64, ctFloat, ctFloat32, ctFloat64, 
    ctFloat128, ctArray, ctStruct, ctPtr, ctNimStr, ctNimSeq, ctProc, ctCString
  TCFileSections = array[TCFileSection, PRope] # represents a generated C file
  TCProcSection* = enum       # the sections a generated C proc consists of
    cpsLocals,                # section of local variables for C proc
    cpsInit,                  # section for init of variables for C proc
    cpsStmts                  # section of local statements for C proc
  TCProcSections = array[TCProcSection, PRope] # represents a generated C proc
  BModule* = ref TCGen
  BProc* = ref TCProc
  TBlock{.final.} = object 
    id*: int                  # the ID of the label; positive means that it
                              # has been used (i.e. the label should be emitted)
    nestedTryStmts*: int      # how many try statements is it nested into
  
  TCProc{.final.} = object    # represents C proc that is currently generated
    s*: TCProcSections        # the procs sections; short name for readability
    prc*: PSym                # the Nimrod proc that this C proc belongs to
    BeforeRetNeeded*: bool    # true iff 'BeforeRet' label for proc is needed
    ThreadVarAccessed*: bool  # true if the proc already accessed some threadvar
    nestedTryStmts*: seq[PNode] # in how many nested try statements we are
                                # (the vars must be volatile then)
    labels*: Natural          # for generating unique labels in the C proc
    blocks*: seq[TBlock]      # nested blocks
    options*: TOptions        # options that should be used for code
                              # generation; this is the same as prc.options
                              # unless prc == nil
    frameLen*: int            # current length of frame descriptor
    sendClosure*: PType       # closure record type that we pass
    receiveClosure*: PType    # closure record type that we get
    module*: BModule          # used to prevent excessive parameter passing
    withinLoop*: int          # > 0 if we are within a loop
  
  TTypeSeq* = seq[PType]
  TCGen = object of TPassContext # represents a C source file
    module*: PSym
    filename*: string
    s*: TCFileSections        # sections of the C file
    PreventStackTrace*: bool  # true if stack traces need to be prevented
    usesThreadVars*: bool     # true if the module uses a thread var
    cfilename*: string        # filename of the module (including path,
                              # without extension)
    typeCache*: TIdTable      # cache the generated types
    forwTypeCache*: TIdTable  # cache for forward declarations of types
    declaredThings*: TIntSet  # things we have declared in this .c file
    declaredProtos*: TIntSet  # prototypes we have declared in this .c file
    headerFiles*: TLinkedList # needed headers to include
    typeInfoMarker*: TIntSet  # needed for generating type information
    initProc*: BProc          # code for init procedure
    typeStack*: TTypeSeq      # used for type generation
    dataCache*: TNodeTable
    forwardedProcs*: TSymSeq  # keep forwarded procs here
    typeNodes*, nimTypes*: int # used for type info generation
    typeNodesName*, nimTypesName*: PRope # used for type info generation
    labels*: natural          # for generating unique module-scope names

var
  mainModProcs*, mainModInit*: PRope # parts of the main module
  gMapping*: PRope             # the generated mapping file (if requested)
  gProcProfile*: Natural       # proc profile counter
  gGeneratedSyms*: TIntSet     # set of ID's of generated symbols
  gPendingModules*: seq[BModule] = @[] # list of modules that are not
                                       # finished with code generation
  gForwardedProcsCounter*: int = 0
  gNimDat*: BModule            # generated global data


proc newProc*(prc: PSym, module: BModule): BProc = 
  new(result)
  result.prc = prc
  result.module = module
  if prc != nil: result.options = prc.options
  else: result.options = gOptions
  result.blocks = @[]
  result.nestedTryStmts = @[]

