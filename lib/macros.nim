#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## This module contains the interface to the compiler's abstract syntax tree.
## Abstract syntax trees should be modified in macros.

#[[[cog
#def toEnum(name, elems):
#  body = ""
#  counter = 0
#  for e in elems:
#    if counter % 4 == 0: p = "\n    "
#    else: p = ""
#    body = body + p + 'n' + e + ', '
#    counter = counter + 1
#
#  return ("  TNimrod%s* = enum%s\n  TNim%ss* = set[TNimrod%s]\n" %
#            (name, body[:-2], name, name))
#
#enums = eval(open("data/ast.yml").read())
#cog.out("type\n")
#for key, val in enums.items():
#  if key[-4:] == "Flag": continue
#  cog.out(toEnum(key, val))
#]]]
type
  TNimrodTypeKind* = enum
    ntyNone, ntyBool, ntyChar, ntyEmpty, 
    ntyArrayConstr, ntyNil, ntyGeneric, ntyGenericInst, 
    ntyGenericParam, ntyEnum, ntyAnyEnum, ntyArray, 
    ntyObject, ntyTuple, ntySet, ntyRange, 
    ntyPtr, ntyRef, ntyVar, ntySequence, 
    ntyProc, ntyPointer, ntyOpenArray, ntyString, 
    ntyCString, ntyForward, ntyInt, ntyInt8, 
    ntyInt16, ntyInt32, ntyInt64, ntyFloat, 
    ntyFloat32, ntyFloat64, ntyFloat128
  TNimTypeKinds* = set[TNimrodTypeKind]
  TNimrodSymKind* = enum
    nskUnknownSym, nskConditional, nskDynLib, nskParam, 
    nskTypeParam, nskTemp, nskType, nskConst, 
    nskVar, nskProc, nskIterator, nskConverter, 
    nskMacro, nskTemplate, nskField, nskEnumField, 
    nskForVar, nskModule, nskLabel, nskStub
  TNimSymKinds* = set[TNimrodSymKind]
  TNimrodNodeKind* = enum
    nnkNone, nnkEmpty, nnkIdent, nnkSym, 
    nnkType, nnkCharLit, nnkIntLit, nnkInt8Lit, 
    nnkInt16Lit, nnkInt32Lit, nnkInt64Lit, nnkFloatLit, 
    nnkFloat32Lit, nnkFloat64Lit, nnkStrLit, nnkRStrLit, 
    nnkTripleStrLit, nnkMetaNode, nnkNilLit, nnkDotCall, 
    nnkCommand, nnkCall, nnkGenericCall, nnkExplicitTypeListCall, 
    nnkExprEqExpr, nnkExprColonExpr, nnkIdentDefs, nnkInfix, 
    nnkPrefix, nnkPostfix, nnkPar, nnkCurly, 
    nnkBracket, nnkBracketExpr, nnkPragmaExpr, nnkRange, 
    nnkDotExpr, nnkCheckedFieldExpr, nnkDerefExpr, nnkIfExpr, 
    nnkElifExpr, nnkElseExpr, nnkLambda, nnkAccQuoted, 
    nnkHeaderQuoted, nnkTableConstr, nnkQualified, nnkHiddenStdConv, 
    nnkHiddenSubConv, nnkHiddenCallConv, nnkConv, nnkCast, 
    nnkAddr, nnkHiddenAddr, nnkHiddenDeref, nnkObjDownConv, 
    nnkObjUpConv, nnkChckRangeF, nnkChckRange64, nnkChckRange, 
    nnkStringToCString, nnkCStringToString, nnkPassAsOpenArray, nnkAsgn, 
    nnkDefaultTypeParam, nnkGenericParams, nnkFormalParams, nnkOfInherit, 
    nnkModule, nnkProcDef, nnkConverterDef, nnkMacroDef, 
    nnkTemplateDef, nnkIteratorDef, nnkOfBranch, nnkElifBranch, 
    nnkExceptBranch, nnkElse, nnkMacroStmt, nnkAsmStmt, 
    nnkPragma, nnkIfStmt, nnkWhenStmt, nnkForStmt, 
    nnkWhileStmt, nnkCaseStmt, nnkVarSection, nnkConstSection, 
    nnkConstDef, nnkTypeSection, nnkTypeDef, nnkYieldStmt, 
    nnkTryStmt, nnkFinally, nnkRaiseStmt, nnkReturnStmt, 
    nnkBreakStmt, nnkContinueStmt, nnkBlockStmt, nnkDiscardStmt, 
    nnkStmtList, nnkImportStmt, nnkFromStmt, nnkImportAs, 
    nnkIncludeStmt, nnkAccessStmt, nnkCommentStmt, nnkStmtListExpr, 
    nnkBlockExpr, nnkStmtListType, nnkBlockType, nnkVm, 
    nnkTypeOfExpr, nnkObjectTy, nnkTupleTy, nnkRecList, 
    nnkRecCase, nnkRecWhen, nnkRefTy, nnkPtrTy, 
    nnkVarTy, nnkProcTy, nnkEnumTy, nnkEnumFieldDef, 
    nnkReturnToken
  TNimNodeKinds* = set[TNimrodNodeKind]
#[[[end]]]

type
  TNimrodNode {.final.} = object   # hidden
  TNimrodSymbol {.final.} = object # hidden
  TNimrodType {.final.} = object   # hidden
  PNimrodType* {.compilerproc.} = ref TNimrodType
  PNimrodSymbol* {.compilerproc.} = ref TNimrodSymbol
  PNimrodNode* {.compilerproc.} = ref TNimrodNode
  expr* = PNimrodNode
  stmt* = PNimrodNode

# Nodes should be reference counted to make the `copy` operation very fast!
# However, this is difficult to achieve: modify(n[0][1]) should propagate to
# its father. How to do this without back references?

proc `[]`* (n: PNimrodNode, i: int): PNimrodNode {.magic: "NChild".}
proc `[]=`* (n: PNimrodNode, i: int, child: PNimrodNode) {.magic: "NSetChild".}
  ## provide access to `n`'s children

type
  TNimrodIdent = object of TObject

converter StrToIdent*(s: string): TNimrodIdent {.magic: "StrToIdent".}
proc `$`*(i: TNimrodIdent): string {.magic: "IdentToStr".}
proc `==`* (a, b: TNimrodIdent): bool {.magic: "EqIdent".}

proc len*(n: PNimrodNode): int {.magic: "NLen".}

## returns the number of children that a node has
proc add*(father, child: PNimrodNode) {.magic: "NAdd".}
proc add*(father: PNimrodNode, child: openArray[PNimrodNode]) {.magic: "NAddMultiple".}
proc del*(father: PNimrodNode, idx = 0, n = 1) {.magic: "NDel".}
proc kind*(n: PNimrodNode): TNimrodNodeKind {.magic: "NKind".}

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
proc warning*(msg: string) {.magic: "NWarning".}
proc hint*(msg: string) {.magic: "NHint".}

proc newStrLitNode*(s: string): PNimrodNode {.compileTime.} =
  result = newNimNode(nnkStrLit)
  result.strVal = s

proc newIntLitNode*(i: biggestInt): PNimrodNode {.compileTime.} =
  result = newNimNode(nnkIntLit)
  result.intVal = i

proc newIntLitNode*(f: biggestFloat): PNimrodNode {.compileTime.} =
  result = newNimNode(nnkFloatLit)
  result.floatVal = f

proc newIdentNode*(i: TNimrodIdent): PNimrodNode {.compileTime.} =
  result = newNimNode(nnkIdent)
  result.ident = i

proc toStrLit*(n: PNimrodNode): PNimrodNode {.compileTime.} =
  return newStrLitNode(repr(n))

proc expectKind*(n: PNimrodNode, k: TNimrodNodeKind) {.compileTime.} =
  if n.kind != k: error("macro expects a node of kind: " & repr(k))

proc expectMinLen*(n: PNimrodNode, min: int) {.compileTime.} =
  if n.len < min: error("macro expects a node with " & $min & " children")

proc newCall*(theProc: TNimrodIdent,
              args: openArray[PNimrodNode]): PNimrodNode {.compileTime.} =
  ## produces a new call node. `theProc` is the proc that is called with
  ## the arguments ``args[0..]``.
  result = newNimNode(nnkCall)
  result.add(newIdentNode(theProc))
  result.add(args)
