#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## This module contains the interface to the compiler's abstract syntax 
## tree (`AST`:idx:). Macros operate on this tree.

## .. include:: ../doc/astspec.txt

type
  TNimrodNodeKind* = enum
    nnkNone, nnkEmpty, nnkIdent, nnkSym, 
    nnkType, nnkCharLit, nnkIntLit, nnkInt8Lit, 
    nnkInt16Lit, nnkInt32Lit, nnkInt64Lit, nnkFloatLit, 
    nnkFloat32Lit, nnkFloat64Lit, nnkStrLit, nnkRStrLit, 
    nnkTripleStrLit, nnkMetaNode, nnkNilLit, nnkDotCall, 
    nnkCommand, nnkCall, nnkCallStrLit, nnkExprEqExpr, 
    nnkExprColonExpr, nnkIdentDefs, nnkVarTuple, nnkInfix, 
    nnkPrefix, nnkPostfix, nnkPar, nnkCurly, 
    nnkBracket, nnkBracketExpr, nnkPragmaExpr, nnkRange, 
    nnkDotExpr, nnkCheckedFieldExpr, nnkDerefExpr, nnkIfExpr, 
    nnkElifExpr, nnkElseExpr, nnkLambda, nnkAccQuoted, 
    nnkTableConstr, nnkBind, nnkSymChoice, nnkHiddenStdConv, 
    nnkHiddenSubConv, nnkHiddenCallConv, nnkConv, nnkCast, 
    nnkAddr, nnkHiddenAddr, nnkHiddenDeref, nnkObjDownConv, 
    nnkObjUpConv, nnkChckRangeF, nnkChckRange64, nnkChckRange, 
    nnkStringToCString, nnkCStringToString, nnkPassAsOpenArray, nnkAsgn, 
    nnkFastAsgn, nnkGenericParams, nnkFormalParams, nnkOfInherit, 
    nnkModule, nnkProcDef, nnkMethodDef, nnkConverterDef, 
    nnkMacroDef, nnkTemplateDef, nnkIteratorDef, nnkOfBranch, 
    nnkElifBranch, nnkExceptBranch, nnkElse, nnkMacroStmt, 
    nnkAsmStmt, nnkPragma, nnkIfStmt, nnkWhenStmt, 
    nnkForStmt, nnkWhileStmt, nnkCaseStmt, nnkVarSection, 
    nnkConstSection, nnkConstDef, nnkTypeSection, nnkTypeDef, 
    nnkYieldStmt, nnkTryStmt, nnkFinally, nnkRaiseStmt, 
    nnkReturnStmt, nnkBreakStmt, nnkContinueStmt, nnkBlockStmt, 
    nnkDiscardStmt, nnkStmtList, nnkImportStmt, nnkFromStmt, 
    nnkIncludeStmt, nnkCommentStmt, nnkStmtListExpr, nnkBlockExpr, 
    nnkStmtListType, nnkBlockType, nnkTypeOfExpr, nnkObjectTy, 
    nnkTupleTy, nnkRecList, nnkRecCase, nnkRecWhen, 
    nnkRefTy, nnkPtrTy, nnkVarTy, nnkDistinctTy, 
    nnkProcTy, nnkEnumTy, nnkEnumFieldDef, nnkReturnToken
  TNimNodeKinds* = set[TNimrodNodeKind]
  TNimrodTypeKind* = enum
    ntyNone, ntyBool, ntyChar, ntyEmpty, 
    ntyArrayConstr, ntyNil, ntyExpr, ntyStmt, 
    ntyTypeDesc, ntyGenericInvokation, ntyGenericBody, ntyGenericInst, 
    ntyGenericParam, ntyDistinct, ntyEnum, ntyOrdinal, 
    ntyArray, ntyObject, ntyTuple, ntySet, 
    ntyRange, ntyPtr, ntyRef, ntyVar, 
    ntySequence, ntyProc, ntyPointer, ntyOpenArray, 
    ntyString, ntyCString, ntyForward, ntyInt, 
    ntyInt8, ntyInt16, ntyInt32, ntyInt64, 
    ntyFloat, ntyFloat32, ntyFloat64, ntyFloat128
  TNimTypeKinds* = set[TNimrodTypeKind]
  TNimrodSymKind* = enum
    nskUnknown, nskConditional, nskDynLib, nskParam, 
    nskGenericParam, nskTemp, nskType, nskConst, 
    nskVar, nskProc, nskMethod, nskIterator, 
    nskConverter, nskMacro, nskTemplate, nskField, 
    nskEnumField, nskForVar, nskModule, nskLabel, 
    nskStub
  TNimSymKinds* = set[TNimrodSymKind]

type
  TNimrodIdent* = object of TObject
    ## represents a Nimrod identifier in the AST

  TNimrodSymbol {.final.} = object # hidden
  TNimrodType {.final.} = object   # hidden
  
  PNimrodType* {.compilerproc.} = ref TNimrodType
    ## represents a Nimrod type in the compiler; currently this is not very
    ## useful as there is no API to deal with Nimrod types.
  
  PNimrodSymbol* {.compilerproc.} = ref TNimrodSymbol
    ## represents a Nimrod *symbol* in the compiler; a *symbol* is a looked-up
    ## *ident*.
  
  PNimrodNode* = expr
    ## represents a Nimrod AST node. Macros operate on this type.
    
# Nodes should be reference counted to make the `copy` operation very fast!
# However, this is difficult to achieve: modify(n[0][1]) should propagate to
# its father. How to do this without back references? Hm, BS, it works without 
# them.

proc `[]`* (n: PNimrodNode, i: int): PNimrodNode {.magic: "NChild".}
  ## get `n`'s `i`'th child.

proc `[]=`* (n: PNimrodNode, i: int, child: PNimrodNode) {.magic: "NSetChild".}
  ## set `n`'s `i`'th child to `child`.

proc `!` *(s: string): TNimrodIdent {.magic: "StrToIdent".}
  ## constructs an identifier from the string `s`

proc `$`*(i: TNimrodIdent): string {.magic: "IdentToStr".}
  ## converts a Nimrod identifier to a string

proc `==`* (a, b: TNimrodIdent): bool {.magic: "EqIdent", noSideEffect.}
  ## compares two Nimrod identifiers

proc `==`* (a, b: PNimrodNode): bool {.magic: "EqNimrodNode", noSideEffect.}
  ## compares two Nimrod nodes

proc len*(n: PNimrodNode): int {.magic: "NLen".}
  ## returns the number of children of `n`.

proc add*(father, child: PNimrodNode) {.magic: "NAdd".}
  ## adds the `child` to the `father` node

proc add*(father: PNimrodNode, children: openArray[PNimrodNode]) {.
  magic: "NAddMultiple".}
  ## adds each child of `children` to the `father` node

proc del*(father: PNimrodNode, idx = 0, n = 1) {.magic: "NDel".}
  ## deletes `n` children of `father` starting at index `idx`. 

proc kind*(n: PNimrodNode): TNimrodNodeKind {.magic: "NKind".}
  ## returns the `kind` of the node `n`.

proc intVal*(n: PNimrodNode): biggestInt {.magic: "NIntVal".}
proc floatVal*(n: PNimrodNode): biggestFloat {.magic: "NFloatVal".}
proc symbol*(n: PNimrodNode): PNimrodSymbol {.magic: "NSymbol".}
proc ident*(n: PNimrodNode): TNimrodIdent {.magic: "NIdent".}
proc typ*(n: PNimrodNode): PNimrodType {.magic: "NGetType".}
proc strVal*(n: PNimrodNode): string  {.magic: "NStrVal".}

proc `intVal=`*(n: PNimrodNode, val: biggestInt) {.magic: "NSetIntVal".}
proc `floatVal=`*(n: PNimrodNode, val: biggestFloat) {.magic: "NSetFloatVal".}
proc `symbol=`*(n: PNimrodNode, val: PNimrodSymbol) {.magic: "NSetSymbol".}
proc `ident=`*(n: PNimrodNode, val: TNimrodIdent) {.magic: "NSetIdent".}
proc `typ=`*(n: PNimrodNode, typ: PNimrodType) {.magic: "NSetType".}
proc `strVal=`*(n: PNimrodNode, val: string) {.magic: "NSetStrVal".}

proc newNimNode*(kind: TNimrodNodeKind,
                 n: PNimrodNode=nil): PNimrodNode {.magic: "NNewNimNode".}

proc copyNimNode*(n: PNimrodNode): PNimrodNode {.magic: "NCopyNimNode".}
proc copyNimTree*(n: PNimrodNode): PNimrodNode {.magic: "NCopyNimTree".}

proc error*(msg: string) {.magic: "NError".}
  ## writes an error message at compile time

proc warning*(msg: string) {.magic: "NWarning".}
  ## writes a warning message at compile time

proc hint*(msg: string) {.magic: "NHint".}
  ## writes a hint message at compile time

proc newStrLitNode*(s: string): PNimrodNode {.compileTime.} =
  ## creates a string literal node from `s`
  result = newNimNode(nnkStrLit)
  result.strVal = s

proc newIntLitNode*(i: biggestInt): PNimrodNode {.compileTime.} =
  ## creates a int literal node from `i`
  result = newNimNode(nnkIntLit)
  result.intVal = i

proc newFloatLitNode*(f: biggestFloat): PNimrodNode {.compileTime.} =
  ## creates a float literal node from `f`
  result = newNimNode(nnkFloatLit)
  result.floatVal = f

proc newIdentNode*(i: TNimrodIdent): PNimrodNode {.compileTime.} =
  ## creates an identifier node from `i`
  result = newNimNode(nnkIdent)
  result.ident = i

proc newIdentNode*(i: string): PNimrodNode {.compileTime.} =
  ## creates an identifier node from `i`
  result = newNimNode(nnkIdent)
  result.ident = !i

proc toStrLit*(n: PNimrodNode): PNimrodNode {.compileTime.} =
  ## converts the AST `n` to the concrete Nimrod code and wraps that 
  ## in a string literal node
  return newStrLitNode(repr(n))

proc expectKind*(n: PNimrodNode, k: TNimrodNodeKind) {.compileTime.} =
  ## checks that `n` is of kind `k`. If this is not the case,
  ## compilation aborts with an error message. This is useful for writing
  ## macros that check the AST that is passed to them.
  if n.kind != k: error("macro expects a node of kind: " & repr(k))

proc expectMinLen*(n: PNimrodNode, min: int) {.compileTime.} =
  ## checks that `n` has at least `min` children. If this is not the case,
  ## compilation aborts with an error message. This is useful for writing
  ## macros that check its number of arguments. 
  if n.len < min: error("macro expects a node with " & $min & " children")

proc expectLen*(n: PNimrodNode, len: int) {.compileTime.} =
  ## checks that `n` has exactly `len` children. If this is not the case,
  ## compilation aborts with an error message. This is useful for writing
  ## macros that check its number of arguments. 
  if n.len != len: error("macro expects a node with " & $len & " children")

proc newCall*(theProc: TNimrodIdent,
              args: openArray[PNimrodNode]): PNimrodNode {.compileTime.} =
  ## produces a new call node. `theProc` is the proc that is called with
  ## the arguments ``args[0..]``.
  result = newNimNode(nnkCall)
  result.add(newIdentNode(theProc))
  result.add(args)
  
proc newCall*(theProc: string,
              args: openArray[PNimrodNode]): PNimrodNode {.compileTime.} =
  ## produces a new call node. `theProc` is the proc that is called with
  ## the arguments ``args[0..]``.
  result = newNimNode(nnkCall)
  result.add(newIdentNode(theProc))
  result.add(args)

proc nestList*(theProc: TNimrodIdent,  
               x: PNimrodNode): PNimrodNode {.compileTime.} = 
  ## nests the list `x` into a tree of call expressions:
  ## ``[a, b, c]`` is transformed into ``theProc(a, theProc(c, d))``
  var L = x.len
  result = newCall(theProc, x[L-2], x[L-1])
  var a = result
  for i in countdown(L-3, 0):
    a = newCall(theProc, x[i], copyNimTree(a))

