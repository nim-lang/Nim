#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains the type definitions for the new evaluation engine.
## An instruction is 1-3 int32s in memory, it is a register based VM.

import ast, passes, msgs, idents, intsets, options, modulegraphs, lineinfos,
  tables, btrees

const
  byteExcess* = 128 # we use excess-K for immediates
  wordExcess* = 32768

  MaxLoopIterations* = 3_000_000 # max iterations of all loops


type
  TRegister* = range[0..255]
  TDest* = range[-1 .. 255]
  TInstr* = distinct uint32

  TOpcode* = enum
    opcEof,         # end of code
    opcRet,         # return
    opcYldYoid,     # yield with no value
    opcYldVal,      # yield with a value

    opcAsgnInt,
    opcAsgnStr,
    opcAsgnFloat,
    opcAsgnRef,
    opcAsgnIntFromFloat32,    # int and float must be of the same byte size
    opcAsgnIntFromFloat64,    # int and float must be of the same byte size
    opcAsgnFloat32FromInt,    # int and float must be of the same byte size
    opcAsgnFloat64FromInt,    # int and float must be of the same byte size
    opcAsgnComplex,
    opcNodeToReg,

    opcLdArr,  # a = b[c]
    opcWrArr,  # a[b] = c
    opcLdObj,  # a = b.c
    opcWrObj,  # a.b = c
    opcAddrReg,
    opcAddrNode,
    opcLdDeref,
    opcWrDeref,
    opcWrStrIdx,
    opcLdStrIdx, # a = b[c]

    opcAddInt,
    opcAddImmInt,
    opcSubInt,
    opcSubImmInt,
    opcLenSeq,
    opcLenStr,

    opcIncl, opcInclRange, opcExcl, opcCard, opcMulInt, opcDivInt, opcModInt,
    opcAddFloat, opcSubFloat, opcMulFloat, opcDivFloat,
    opcShrInt, opcShlInt, opcAshrInt,
    opcBitandInt, opcBitorInt, opcBitxorInt, opcAddu, opcSubu, opcMulu,
    opcDivu, opcModu, opcEqInt, opcLeInt, opcLtInt, opcEqFloat,
    opcLeFloat, opcLtFloat, opcLeu, opcLtu,
    opcEqRef, opcEqNimNode, opcSameNodeType,
    opcXor, opcNot, opcUnaryMinusInt, opcUnaryMinusFloat, opcBitnotInt,
    opcEqStr, opcLeStr, opcLtStr, opcEqSet, opcLeSet, opcLtSet,
    opcMulSet, opcPlusSet, opcMinusSet, opcSymdiffSet, opcConcatStr,
    opcContainsSet, opcRepr, opcSetLenStr, opcSetLenSeq,
    opcIsNil, opcOf, opcIs,
    opcSubStr, opcParseFloat, opcConv, opcCast,
    opcQuit,
    opcNarrowS, opcNarrowU,
    opcSignExtend,

    opcAddStrCh,
    opcAddStrStr,
    opcAddSeqElem,
    opcRangeChck,

    opcNAdd,
    opcNAddMultiple,
    opcNKind,
    opcNSymKind,
    opcNIntVal,
    opcNFloatVal,
    opcNSymbol,
    opcNIdent,
    opcNGetType,
    opcNStrVal,
    opcNSigHash,

    opcNSetIntVal,
    opcNSetFloatVal, opcNSetSymbol, opcNSetIdent, opcNSetType, opcNSetStrVal,
    opcNNewNimNode, opcNCopyNimNode, opcNCopyNimTree, opcNDel, opcGenSym,

    opcNccValue, opcNccInc, opcNcsAdd, opcNcsIncl, opcNcsLen, opcNcsAt,
    opcNctPut, opcNctLen, opcNctGet, opcNctHasNext, opcNctNext,

    opcSlurp,
    opcGorge,
    opcParseExprToAst,
    opcParseStmtToAst,
    opcQueryErrorFlag,
    opcNError,
    opcNWarning,
    opcNHint,
    opcNGetLineInfo, opcNSetLineInfo,
    opcEqIdent,
    opcStrToIdent,
    opcGetImpl,
    opcGetImplTransf

    opcEcho,
    opcIndCall, # dest = call regStart, n; where regStart = fn, arg1, ...
    opcIndCallAsgn, # dest = call regStart, n; where regStart = fn, arg1, ...

    opcRaise,
    opcNChild,
    opcNSetChild,
    opcCallSite,
    opcNewStr,

    opcTJmp,  # jump Bx if A != 0
    opcFJmp,  # jump Bx if A == 0
    opcJmp,   # jump Bx
    opcJmpBack, # jump Bx; resulting from a while loop
    opcBranch,  # branch for 'case'
    opcTry,
    opcExcept,
    opcFinally,
    opcFinallyEnd,
    opcNew,
    opcNewSeq,
    opcLdNull,    # dest = nullvalue(types[Bx])
    opcLdNullReg,
    opcLdConst,   # dest = constants[Bx]
    opcAsgnConst, # dest = copy(constants[Bx])
    opcLdGlobal,  # dest = globals[Bx]
    opcLdGlobalAddr, # dest = addr(globals[Bx])

    opcLdImmInt,  # dest = immediate value
    opcNBindSym, opcNDynBindSym,
    opcSetType,   # dest.typ = types[Bx]
    opcTypeTrait,
    opcMarshalLoad, opcMarshalStore,
    opcToNarrowInt,
    opcSymOwner,
    opcSymIsInstantiationOf

  TBlock* = object
    label*: PSym
    fixups*: seq[TPosition]

  TEvalMode* = enum           ## reason for evaluation
    emRepl,                   ## evaluate because in REPL mode
    emConst,                  ## evaluate for 'const' according to spec
    emOptimize,               ## evaluate for optimization purposes (same as
                              ## emConst?)
    emStaticExpr,             ## evaluate for enforced compile time eval
                              ## ('static' context)
    emStaticStmt              ## 'static' as an expression

  TSandboxFlag* = enum        ## what the evaluation engine should allow
    allowCast,                ## allow unsafe language feature: 'cast'
    allowInfiniteLoops        ## allow endless loops
  TSandboxFlags* = set[TSandboxFlag]

  TSlotKind* = enum   # We try to re-use slots in a smart way to
                      # minimize allocations; however the VM supports arbitrary
                      # temporary slot usage. This is required for the parameter
                      # passing implementation.
    slotEmpty,        # slot is unused
    slotFixedVar,     # slot is used for a fixed var/result (requires copy then)
    slotFixedLet,     # slot is used for a fixed param/let
    slotTempUnknown,  # slot but type unknown (argument of proc call)
    slotTempInt,      # some temporary int
    slotTempFloat,    # some temporary float
    slotTempStr,      # some temporary string
    slotTempComplex,  # some complex temporary (s.node field is used)
    slotTempPerm      # slot is temporary but permanent (hack)

  PProc* = ref object
    blocks*: seq[TBlock]    # blocks; temp data structure
    sym*: PSym
    slots*: array[TRegister, tuple[inUse: bool, kind: TSlotKind]]
    maxSlots*: int

  VmArgs* = object
    ra*, rb*, rc*: Natural
    slots*: pointer
    currentException*: PNode
    currentLineInfo*: TLineInfo
  VmCallback* = proc (args: VmArgs) {.closure.}

  PCtx* = ref TCtx
  TCtx* = object of TPassContext # code gen context
    code*: seq[TInstr]
    debug*: seq[TLineInfo]  # line info for every instruction; kept separate
                            # to not slow down interpretation
    globals*: PNode         #
    constants*: PNode       # constant data
    types*: seq[PType]      # some instructions reference types (e.g. 'except')
    currentExceptionA*, currentExceptionB*: PNode
    exceptionInstr*: int # index of instruction that raised the exception
    prc*: PProc
    module*: PSym
    callsite*: PNode
    mode*: TEvalMode
    features*: TSandboxFlags
    traceActive*: bool
    loopIterations*: int
    comesFromHeuristic*: TLineInfo # Heuristic for better macro stack traces
    callbacks*: seq[tuple[key: string, value: VmCallback]]
    errorFlag*: string
    cache*: IdentCache
    config*: ConfigRef
    graph*: ModuleGraph
    oldErrorCount*: int

  TPosition* = distinct int

  PEvalContext* = PCtx

proc newCtx*(module: PSym; cache: IdentCache; g: ModuleGraph): PCtx =
  PCtx(code: @[], debug: @[],
    globals: newNode(nkStmtListExpr), constants: newNode(nkStmtList), types: @[],
    prc: PProc(blocks: @[]), module: module, loopIterations: MaxLoopIterations,
    comesFromHeuristic: unknownLineInfo(), callbacks: @[], errorFlag: "",
    cache: cache, config: g.config, graph: g)

proc refresh*(c: PCtx, module: PSym) =
  c.module = module
  c.prc = PProc(blocks: @[])
  c.loopIterations = MaxLoopIterations

proc registerCallback*(c: PCtx; name: string; callback: VmCallback): int {.discardable.} =
  result = c.callbacks.len
  c.callbacks.add((name, callback))

const
  firstABxInstr* = opcTJmp
  largeInstrs* = { # instructions which use 2 int32s instead of 1:
    opcSubStr, opcConv, opcCast, opcNewSeq, opcOf,
    opcMarshalLoad, opcMarshalStore}
  slotSomeTemp* = slotTempUnknown
  relativeJumps* = {opcTJmp, opcFJmp, opcJmp, opcJmpBack}

# flag is used to signal opcSeqLen if node is NimNode.
const nimNodeFlag* = 16

template opcode*(x: TInstr): TOpcode = TOpcode(x.uint32 and 0xff'u32)
template regA*(x: TInstr): TRegister = TRegister(x.uint32 shr 8'u32 and 0xff'u32)
template regB*(x: TInstr): TRegister = TRegister(x.uint32 shr 16'u32 and 0xff'u32)
template regC*(x: TInstr): TRegister = TRegister(x.uint32 shr 24'u32)
template regBx*(x: TInstr): int = (x.uint32 shr 16'u32).int

template jmpDiff*(x: TInstr): int = regBx(x) - wordExcess
