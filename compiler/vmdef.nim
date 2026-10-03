#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains the type definitions for the evaluation engine.
## It is a register based VM that works on "packed data": values are laid
## out in memory like the C backend lays them out (see `vmlayout`), all VM
## memory is managed by `vmmem`.
##
## Registers are 8 byte *slots* of the current stack frame; register `i`
## lives at the frame pointer + `8*i`. A scalar (integer, float, pointer,
## handle) that is held in a register is always widened to 64 bits; an
## aggregate value (object, tuple, array, string, seq, closure, ...) that is
## held in registers occupies `ceil(size/8)` consecutive slots and uses the
## packed memory layout. Memory outside of registers is always packed and is
## accessed via typed loads and stores that narrow and widen scalars.
##
## An instruction is a 64 bit word: opcode (8 bits), A, B, C (16 bits each)
## and X (8 bits). X usually holds a `MemKind`. Some instructions are followed
## by an extra 64 bit word `W` that holds an immediate value.

import std/[tables, strutils, intsets]

import ast, idents, options, modulegraphs, lineinfos, vmlayout, vmmem

export vmlayout, vmmem

type TInstrType* = uint64

const
  regOBits = 8 # Opcode
  regABits = 16
  regBBits = 16
  regCBits = 16
  regXBits = 8
  regBxBits = 24

  byteExcess* = 128 # we use excess-K for immediates

# Calculate register shifts, masks and ranges

const
  regOShift* = 0.TInstrType
  regAShift* = (regOShift + regOBits)
  regBShift* = (regAShift + regABits)
  regCShift* = (regBShift + regBBits)
  regXShift* = (regCShift + regCBits)
  regBxShift* = (regAShift + regABits)

  regOMask*  = ((1.TInstrType shl regOBits) - 1)
  regAMask*  = ((1.TInstrType shl regABits) - 1)
  regBMask*  = ((1.TInstrType shl regBBits) - 1)
  regCMask*  = ((1.TInstrType shl regCBits) - 1)
  regXMask*  = ((1.TInstrType shl regXBits) - 1)
  regBxMask* = ((1.TInstrType shl regBxBits) - 1)

  wordExcess* = 1 shl (regBxBits-1)
  regBxMin* = -wordExcess+1
  regBxMax* =  wordExcess-1

  SlotSize* = 8 ## size of a register in bytes
  MaxFrameSlots* = int(regAMask) + 1

type
  TRegister* = range[0..regAMask.int]
  TDest* = range[-1..regAMask.int]
  TInstr* = distinct TInstrType

  TOpcode* = enum
    # Notation: A, B, C are registers (slot indexes), `regs[A]` is the 64 bit
    # value in slot A, `@A` is the address of slot A, `mem[p]` is memory at
    # address `p`, `W` is the 64 bit word that follows the instruction and
    # X is the 8 bit X field. Unless stated otherwise strings, seqs, openArrays
    # and big sets are passed by address: `regs[A]` is the address of the value.
    opcEof,         # end of code; the result is in register A
    opcRet,         # return
    opcYldYoid,     # yield with no value
    opcYldVal,      # yield with a value

    # moves and immediates:
    opcMov,         # regs[A] = regs[B]
    opcMovN,        # copy C slots starting at B to A
    opcZeroN,       # zero B slots starting at A
    opcLdImmInt,    # regs[A] = Bx (signed)
    opcLdImm,       # regs[A] = W

    # addresses, loads and stores:
    opcAddrSlot,    # regs[A] = @B
    opcAddrOff,     # regs[A] = regs[B] + C
    opcAddrOffW,    # regs[A] = regs[B] + W
    opcLd,          # regs[A] = widen(X, mem[regs[B] + C])
    opcSt,          # mem[regs[A] + B] = narrow(X, regs[C])
    opcLdSlot,      # regs[A] = widen(X, @B)  (for locals whose address is taken)
    opcStSlot,      # @A = narrow(X, regs[C])
    opcCopyMem,     # copy W bytes from regs[B] to regs[A]
    opcZeroMem,     # zero W bytes at regs[A]
    opcIdxArr,      # regs[A] = regs[B] + regs[C]*elemSize; W = elemSize | len shl 32; checks 0 <= regs[C] < len
    opcIdxSeq,      # regs[A] = p + dataOffset + regs[C]*elemSize where (len, p) is the seq/string at regs[B];
                    # W = elemSize | dataOffset shl 32; checks 0 <= regs[C] < len
    opcIdxOpenArr,  # regs[A] = data + regs[C]*W where (data, len) is the openArray at regs[B]; checks the index
    opcIdxPtr,      # regs[A] = regs[B] + regs[C]*W; unchecked (UncheckedArray, cstring)
    opcSlice,       # openArray at @A = (data + lo*W, hi-lo+1) where data, len, lo, hi are
                    # in the registers B, B+1, B+2, B+3; checks the bounds

    # integer and float arithmetic, comparisons:
    opcAddInt,
    opcAddImmInt,   # regs[A] = regs[B] + (C - byteExcess)
    opcSubInt,
    opcSubImmInt,
    opcMulInt, opcDivInt, opcModInt,
    opcAddFloat, opcSubFloat, opcMulFloat, opcDivFloat,
    opcShrInt, opcShlInt, opcAshrInt,
    opcBitandInt, opcBitorInt, opcBitxorInt, opcAddu, opcSubu, opcMulu,
    opcDivu, opcModu, opcEqInt, opcLeInt, opcLtInt, opcEqFloat,
    opcLeFloat, opcLtFloat, opcLeu, opcLtu,
    opcXor, opcNot, opcUnaryMinusInt, opcUnaryMinusFloat, opcBitnotInt,
    opcIsNil,       # regs[A] = regs[B] == 0

    # conversions:
    opcCastIntToFloat32,    # int and float must be of the same byte size
    opcCastIntToFloat64,    # int and float must be of the same byte size
    opcCastFloatToInt32,    # int and float must be of the same byte size
    opcCastFloatToInt64,    # int and float must be of the same byte size
    opcIntToFloat,  # regs[A] = float(regs[B])
    opcUIntToFloat, # regs[A] = float(uint64(regs[B]))
    opcFloatToInt,  # regs[A] = int(regs[B]); range checked against W = typeHandle
    opcFloatToUInt, # regs[A] = uint64(regs[B])
    opcFloatToF32,  # regs[A] = float64(float32(regs[B]))
    opcNarrowS, opcNarrowU,  # narrow regs[A] to B bits; range checked
    opcSignExtend,  # sign extend regs[A] from B bits
    opcRangeChck,   # check regs[B] <= regs[A] <= regs[C]
    opcToStr,       # string at regs[A] = $regs[B] where regs[B] is of type W (a type handle)
    opcParseFloat,  # regs[A] = parseBiggestFloat(string at regs[B], mem[regs[C]])

    # sets that fit into a register (up to 64 elements):
    opcSetIncl,     # regs[A] = regs[A] or (1 shl regs[B])
    opcSetExcl,     # regs[A] = regs[A] and not (1 shl regs[B])
    opcSetInclRange,# include bits regs[B]..regs[C] in regs[A]
    opcSetContains, # regs[A] = bit regs[C] of regs[B]
    opcSetCard,     # regs[A] = popcount(regs[B])
    opcSetLe,       # regs[A] = (regs[B] and not regs[C]) == 0
    opcSetLt,       # regs[A] = regs[B] <= regs[C] and regs[B] != regs[C]
    # big sets; W is the size in bytes:
    opcBSetIncl,    # include bit regs[B] in the set at regs[A]
    opcBSetExcl,
    opcBSetInclRange, # include bits regs[B]..regs[C] in the set at regs[A]
    opcBSetContains,  # regs[A] = bit regs[C] of the set at regs[B]
    opcBSetCard,    # regs[A] = card(set at regs[B])
    opcBSetUnion,   # set at regs[A] = set at regs[B] + set at regs[C]
    opcBSetInter, opcBSetDiff, opcBSetXor,
    opcBSetEq, opcBSetLe, opcBSetLt, # regs[A] = cmp(set at regs[B], set at regs[C])

    # strings:
    opcStrNew,      # string at regs[A] = newString(regs[B]); regs[A] must not own a payload
    opcStrSetLen,   # setLen(string at regs[A], regs[B])
    opcStrAddCh,    # add(string at regs[A], char regs[B])
    opcStrAddStr,   # add(string at regs[A], string at regs[B])
    opcStrAsgn,     # `=copy`(string at regs[A], string at regs[B])
    opcStrEq, opcStrLe, opcStrLt, # regs[A] = cmp(string at regs[B], string at regs[C])
    opcStrToCStr,   # regs[A] = cstring of the string at regs[B]
    opcCStrToStr,   # string at regs[A] = $cstring(regs[B]); regs[A] must not own a payload
    opcCStrLen,     # regs[A] = len(cstring(regs[B]))
    opcCStrEq,      # regs[A] = cstring(regs[B]) == cstring(regs[C])
    opcStrFromChars,# string at regs[A] = the chars of the openArray at regs[B]

    # seqs; W = elemSize | elemAlign shl 32:
    opcSeqNew,      # seq at regs[A] = newSeq(regs[B]); regs[A] must not own a payload
    opcSeqSetLen,   # setLen(seq at regs[A], regs[B]); does not destroy elements
    opcSeqGrowOne,  # regs[A] = address of a new, last element of the seq at regs[B]
    opcSeqData,     # regs[A] = address of the first element of the seq/string at regs[B]; W = data offset
    opcPayloadFree, # frees the payload of the seq/string at regs[A] unless it is a literal
    opcSamePayload, # regs[A] = payload(regs[B]) == payload(regs[C])
    opcSeqCopyPayload, # setLen(seq at regs[A], len(seq at regs[B])) and copy the bits of all elements
    opcMakeUnique,  # copy-on-write: the string at regs[A] gets its own payload if it shares a literal
    opcUnshare,     # the strings and seqs in the value at regs[A] of type W get their own
                    # payloads; value semantics for the old runtime (--mm:refc)

    # refs and objects:
    opcNewRef,      # regs[A] = a new zeroed ref cell; W = size | align shl 32
    opcIncRef,      # incRef(regs[A]) unless nil
    opcDecRefIsLast,# regs[A] = decRefIsLast(regs[B]); false for nil
    opcDisposeRef,  # frees the ref cell regs[A]; B is the alignment of the object
    opcDynDestructor, # calls `=destroy` for the dynamic type of the ref cell regs[A], then frees it
    opcInitObj,     # sets the type headers of the (zeroed) value at regs[A] of type W, recursively
    opcOf,          # regs[A] = object at regs[B] is of type W (a type handle); false for nil
    opcIs,          # regs[A] = typedesc regs[B] is type W

    # raw memory:
    opcAlloc,       # regs[A] = alloc0(regs[B])
    opcDealloc,     # dealloc(regs[A])
    opcRealloc,     # regs[A] = realloc0(regs[B], regs[C])
    opcMemMove,     # moveMem(regs[A], regs[B], regs[C])
    opcMemZero,     # zeroMem(regs[A], regs[B])
    opcMemCmp,      # regs[A] = cmpMem(regs[B], regs[B+1], regs[B+2])

    opcRepr,        # string at regs[A] = repr(value at regs[B] of type W)
    opcQuit,
    opcInvalidField,# raises a FieldDefect; string message at regs[A], discriminator regs[B]

    # NimNode and typedesc handles; strings are passed by address:
    opcNLen,        # regs[A] = len(node regs[B])
    opcToNode,      # regs[A] = the value in register(s) B of type W as a literal NimNode
    opcFromNode,    # register(s) A = the NimNode in register B as a value of type W
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
    opcNGetSize,

    opcNSetIntVal,
    opcNSetFloatVal, opcNSetSymbol, opcNSetIdent, opcNSetStrVal,
    opcNNewNimNode, opcNCopyNimNode, opcNCopyNimTree, opcNDel, opcGenSym,

    opcNccValue, opcNccInc, opcNcsAdd, opcNcsIncl, opcNcsLen, opcNcsAt,
    opcNctPut, opcNctLen, opcNctGet, opcNctHasNext,
    opcNctNext,     # value at @A = next(table regs[B], regs[C]) of type W
    opcNodeId,

    opcSlurp,
    opcGorge,
    opcParseExprToAst,
    opcParseStmtToAst,
    opcQueryErrorFlag,
    opcNError,
    opcNWarning,
    opcNHint,
    opcNGetLineInfo, opcNCopyLineInfo, opcNSetLineInfoLine,
    opcNSetLineInfoColumn, opcNSetLineInfoFile
    opcEqIdent,     # X: bit 0 set if B is a string, bit 1 set if C is a string
    opcStrToIdent,
    opcGetImpl,
    opcGetImplTransf
    opcEqNimNode,
    opcSameNodeType,
    opcTypeTrait,
    opcSymOwner,
    opcSymIsInstantiationOf,
    opcNBindSym,    # regs[A] = copyTree(node regs[B])
    opcNDynBindSym, # regs[A] = dynamic bindSym; the arguments start at B, W indexes `callShapes`
    opcNChild,
    opcNSetChild,
    opcCallSite,

    opcEcho,        # echo the C strings that start at register A
    opcIndCall,     # call; B is the start of the call area, C its size in slots

    opcRaise,

    opcTJmp,  # jump Bx if A != 0
    opcFJmp,  # jump Bx if A == 0
    opcJmp,   # jump Bx
    opcJmpBack, # jump Bx; resulting from a while loop
    opcBranch,  # branch for 'case'
    opcTry,
    opcExcept,
    opcFinally,
    opcFinallyEnd,
    opcTypeLit      # regs[A] = type handle Bx

  TBlock* = object
    label*: PSym
    fixups*: seq[TPosition]
    tryDepth*: int          # number of enclosing `try` statements

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
    allowInfiniteRecursion    ## allow infinite recursion
  TSandboxFlags* = set[TSandboxFlag]

  SlotUse* = object ## per register bookkeeping of the code generator
    inUse*: bool
    isTemp*: bool   # a temporary; locals and params are not temporaries
    rangeLen*: int32 # for the first slot of a range: the number of slots

  LocalInfo* = object
    slot*: int32    # -1 if not allocated
    boxed*: bool    # a big value that lives on the heap; the slot holds its address
    inMemory*: bool ## a scalar whose address is taken is stored packed in
                    ## its slot and must be accessed via opcLdSlot/opcStSlot

  TryInfo* = object
    fin*: PNode             # the `finally` section or nil
    hasSafePoint*: bool     # false inside of `except` sections

  PProc* = ref object
    blocks*: seq[TBlock]    # blocks; temp data structure
    tries*: seq[TryInfo]    # enclosing `try` statements; for `break`
    sym*: PSym
    regInfo*: seq[SlotUse]
    locals*: Table[ItemId, LocalInfo]
    addrTaken*: IntSet      # ids of locals whose address is taken
    paramAddrTaken*: IntSet # positions of parameters whose address is taken
    resultAddrTaken*: bool
    paramSlots*: seq[LocalInfo] # by parameter position; macros copy their parameters
    resultInfo*: LocalInfo
    hasResult*: bool

  CallShape* = object
    ## where the arguments of a call live, relative to the first argument slot
    paramOffsets*: seq[int] # byte offsets
    paramTypes*: seq[PType]
    resultType*: PType
    resultSlots*: int
    callbackIdx*: int       # for opcNDynBindSym

  VmArgs* = object
    ## the arguments of a callback. See vmhooks for how to access them.
    ctxp*: pointer          # the PCtx; untyped to avoid a cycle
    args*: Address          # address of the first parameter slot
    res*: Address           # address of the result slot(s)
    shape*: ptr CallShape
    currentException*: Address
    currentLineInfo*: TLineInfo
  VmCallback* = proc (args: VmArgs) {.closure.}

  PCtx* = ref TCtx

  VmProcInfo* = object
    pc*: int32
    frameSlots*: int32      # size of the frame in slots
    resultSlots*: int32     # slots of the result
    paramSlots*: int32      # slots of the parameters
    envSlot*: int32         # slot of the closure environment or -1
    genericParamSlots*: seq[int32] # macros: slots of the generic parameters

  TCtx* = object of TPassContext # code gen context
    code*: seq[TInstr]
    lastEof*: int ## position of the last `opcEof`; -1 if there is none
    typeKindDefault*: int # 1 + the result of `typeKind` for an untyped node; 0 for `ntyNone`
    debug*: seq[TLineInfo]  # line info for every instruction; kept separate
                            # to not slow down interpretation
    mem*: VmMemory          # all memory of the VM
    layouts*: LayoutCache
    globalAddrs*: Table[ItemId, Address] # compile-time globals
    constAddrs*: Table[ItemId, Address]  # values of `const` symbols
    branchTables*: seq[seq[(BiggestInt, BiggestInt)]] # for opcBranch
    callShapes*: seq[CallShape] # for opcNDynBindSym
    procShapes*: Table[ItemId, CallShape] # for callbacks
    excNames*: Table[int, Address] # exception type id -> cstring of its name
    semCtx*: PPassContext   # the PContext of the current evaluation, for lifting hooks
    emptyCStr*: Address
    currentExceptionA*, currentExceptionB*: Address
    exceptionInstr*: int # index of instruction that raised the exception
    prc*: PProc
    module*: PSym
    callsite*: PNode
    mode*: TEvalMode
    features*: TSandboxFlags
    traceActive*: bool
    loopIterations*, callDepth*: int
    comesFromHeuristic*: TLineInfo # Heuristic for better macro stack traces
    callbacks*: seq[VmCallback]
    callbackIndex*: Table[string, int]
    errorFlag*: string
    cache*: IdentCache
    config*: ConfigRef
    graph*: ModuleGraph
    oldErrorCount*: int
    profiler*: Profiler
    templInstCounter*: ref int # gives every template instantiation a unique ID, needed here for getAst
    vmstateDiff*: seq[(PSym, PNode)] # we remember the "diff" to global state here (feature for IC)
    procToCodePos*: Table[int, VmProcInfo]
    cannotEval*: bool
    locals*: IntSet

  PStackFrame* = ref TStackFrame
  TStackFrame* {.acyclic.} = object
    prc*: PSym                 # current prc; proc that is evaluated
    fp*: Address               # the frame pointer: address of slot 0
    mark*: StackMark           # the stack pointer before this frame was pushed
    next*: PStackFrame         # for stacking
    comesFrom*: int
    top*: StackMark            # the stack pointer after this frame was pushed
    resultDest*: Address       # where the caller wants the result
    resultSize*: int
    disposeOnReturn*: Address  # a ref cell to free when the frame returns
    disposeAlign*: int
    safePoints*: seq[int]      # used for exception handling
                              # XXX 'break' should perform cleanup actions
                              # What does the C backend do for it?
  Profiler* = object
    tEnter*: float
    tos*: PStackFrame

  TPosition* = distinct int

  PEvalContext* = PCtx

const
  NoVmProcInfo* = VmProcInfo(pc: 0'i32, frameSlots: -1'i32)

proc newCtx*(module: PSym; cache: IdentCache; g: ModuleGraph; idgen: IdGenerator): PCtx =
  PCtx(code: @[], lastEof: -1, debug: @[],
    prc: PProc(blocks: @[]), module: module, loopIterations: g.config.maxLoopIterationsVM,
    callDepth: g.config.maxCallDepthVM,
    comesFromHeuristic: unknownLineInfo, callbacks: @[], callbackIndex: initTable[string, int](), errorFlag: "",
    cache: cache, config: g.config, graph: g, idgen: idgen,
    templInstCounter: new int)

proc refresh*(c: PCtx, module: PSym; idgen: IdGenerator) =
  c.module = module
  c.prc = PProc(blocks: @[])
  c.loopIterations = c.config.maxLoopIterationsVM
  c.callDepth = c.config.maxCallDepthVM
  c.idgen = idgen

proc reverseName(s: string): string =
  result = newStringOfCap(s.len)
  let y = s.split('.')
  for i in 1..y.len:
    result.add y[^i]
    if i != y.len:
      result.add '.'

proc registerCallback*(c: PCtx; name: string; callback: VmCallback): int {.discardable.} =
  result = c.callbacks.len
  c.callbacks.add(callback)
  c.callbackIndex[reverseName(name)] = result

const
  firstABxInstr* = opcTJmp
  largeInstrs* = { # instructions which are followed by an extra word W:
    opcLdImm, opcAddrOffW, opcCopyMem, opcZeroMem,
    opcIdxArr, opcIdxSeq, opcIdxOpenArr, opcIdxPtr,
    opcFloatToInt, opcToStr,
    opcBSetIncl, opcBSetExcl, opcBSetInclRange, opcBSetContains, opcBSetCard,
    opcBSetUnion, opcBSetInter, opcBSetDiff, opcBSetXor,
    opcBSetEq, opcBSetLe, opcBSetLt,
    opcSeqNew, opcSeqSetLen, opcSeqGrowOne, opcSeqData, opcSeqCopyPayload,
    opcNewRef, opcInitObj, opcOf, opcIs, opcRepr, opcSlice, opcNDynBindSym, opcToNode, opcFromNode,
    opcUnshare,
    opcNctNext, opcInvalidField
    }
  relativeJumps* = {opcTJmp, opcFJmp, opcJmp, opcJmpBack}

template opcode*(x: TInstr): TOpcode = TOpcode(x.TInstrType shr regOShift and regOMask)
template regA*(x: TInstr): TRegister = TRegister(x.TInstrType shr regAShift and regAMask)
template regB*(x: TInstr): TRegister = TRegister(x.TInstrType shr regBShift and regBMask)
template regC*(x: TInstr): TRegister = TRegister(x.TInstrType shr regCShift and regCMask)
template regX*(x: TInstr): int = int(x.TInstrType shr regXShift and regXMask)
template regBx*(x: TInstr): int = (x.TInstrType shr regBxShift and regBxMask).int

template jmpDiff*(x: TInstr): int = regBx(x) - wordExcess

proc slotsFor*(size: int): int {.inline.} =
  ## number of registers that a value of `size` bytes occupies.
  max((size + SlotSize - 1) div SlotSize, 1)
