#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
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
    nnkTripleStrLit, nnkNilLit, nnkMetaNode, nnkDotCall, 
    nnkCommand, nnkCall, nnkCallStrLit, nnkExprEqExpr, 
    nnkExprColonExpr, nnkIdentDefs, nnkVarTuple, nnkInfix, 
    nnkPrefix, nnkPostfix, nnkPar, nnkCurly, nnkCurlyExpr,
    nnkBracket, nnkBracketExpr, nnkPragmaExpr, nnkRange, 
    nnkDotExpr, nnkCheckedFieldExpr, nnkDerefExpr, nnkIfExpr, 
    nnkElifExpr, nnkElseExpr, nnkLambda, nnkAccQuoted, 
    nnkTableConstr, nnkBind, nnkSymChoice, nnkHiddenStdConv, 
    nnkHiddenSubConv, nnkHiddenCallConv, nnkConv, nnkCast, 
    nnkAddr, nnkHiddenAddr, nnkHiddenDeref, nnkObjDownConv, 
    nnkObjUpConv, nnkChckRangeF, nnkChckRange64, nnkChckRange, 
    nnkStringToCString, nnkCStringToString, nnkAsgn, 
    nnkFastAsgn, nnkGenericParams, nnkFormalParams, nnkOfInherit, 
    nnkModule, nnkProcDef, nnkMethodDef, nnkConverterDef, 
    nnkMacroDef, nnkTemplateDef, nnkIteratorDef, nnkOfBranch, 
    nnkElifBranch, nnkExceptBranch, nnkElse, nnkMacroStmt, 
    nnkAsmStmt, nnkPragma, nnkIfStmt, nnkWhenStmt, 
    nnkForStmt, nnkWhileStmt, nnkCaseStmt, 
    nnkTypeSection, nnkVarSection, nnkLetSection, nnkConstSection, 
    nnkConstDef, nnkTypeDef, 
    nnkYieldStmt, nnkTryStmt, nnkFinally, nnkRaiseStmt, 
    nnkReturnStmt, nnkBreakStmt, nnkContinueStmt, nnkBlockStmt, 
    nnkDiscardStmt, nnkStmtList, nnkImportStmt, nnkFromStmt, 
    nnkIncludeStmt, nnkBindStmt,
    nnkCommentStmt, nnkStmtListExpr, nnkBlockExpr, 
    nnkStmtListType, nnkBlockType, nnkTypeOfExpr, nnkObjectTy, 
    nnkTupleTy, nnkRecList, nnkRecCase, nnkRecWhen, 
    nnkRefTy, nnkPtrTy, nnkVarTy, 
    nnkConstTy, nnkMutableTy,
    nnkDistinctTy, 
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

proc lineinfo*(n: PNimrodNode): string {.magic: "NLineInfo".}
  ## returns the position the node appears in the original source file
  ## in the form filename(line, col)

proc parseExpr*(s: string): expr {.magic: "ParseExprToAst".}
  ## Compiles the passed string to its AST representation.
  ## Expects a single expression.

proc parseStmt*(s: string): stmt {.magic: "ParseStmtToAst".}
  ## Compiles the passed string to its AST representation.
  ## Expects one or more statements.

proc getAst*(macroOrTemplate: expr): expr {.magic: "ExpandToAst".}
  ## Obtains the AST nodes returned from a macro or template invocation.
  ## Example:
  ## 
  ## .. code-block:: nimrod
  ##
  ##   macro FooMacro() = 
  ##     var ast = getAst(BarTemplate())
  
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

proc treeRepr*(n: PNimrodNode): string {.compileTime.} =
  ## Convert the AST `n` to a human-readable tree-like string
  ##
  ## see also `repr` and `lispRepr`

  proc traverse(res: var string, level: int, n: PNimrodNode) =
    for i in 0..level-1: res.add "  "
    
    if n == nil:
      res.add "nil"
    else:
      res.add(($n.kind).substr(3))
      
      case n.kind
      of nnkEmpty: nil # same as nil node in this representation
      of nnkNilLit: res.add(" nil")
      of nnkCharLit..nnkInt64Lit: res.add(" " & $n.intVal)
      of nnkFloatLit..nnkFloat64Lit: res.add(" " & $n.floatVal)
      of nnkStrLit..nnkTripleStrLit: res.add(" " & $n.strVal)
      of nnkIdent: res.add(" !\"" & $n.ident & '"')
      of nnkSym, nnkNone: assert false
      else:
        for j in 0..n.len-1:
          res.add "\n"
          traverse(res, level + 1, n[j])

  result = ""
  traverse(result, 0, n)

proc lispRepr*(n: PNimrodNode): string {.compileTime.} =
  ## Convert the AST `n` to a human-readable lisp-like string
  ##
  ## see also `repr` and `treeRepr`
  
  if n == nil: return "nil"

  result = ($n.kind).substr(3)
  add(result, "(")
  
  case n.kind
  of nnkEmpty: nil # same as nil node in this representation
  of nnkNilLit: add(result, "nil")
  of nnkCharLit..nnkInt64Lit: add(result, $n.intVal)
  of nnkFloatLit..nnkFloat64Lit: add(result, $n.floatVal)
  of nnkStrLit..nnkTripleStrLit: add(result, $n.strVal)
  of nnkIdent: add(result, "!\"" & $n.ident & '"')
  of nnkSym, nnkNone: assert false
  else:
    add(result, lispRepr(n[0]))
    for j in 1..n.len-1:
      add(result, ", ")
      add(result, lispRepr(n[j]))

  add(result, ")")

macro dumpTree*(s: stmt): stmt = echo s[1].treeRepr
  ## Accepts a block of nimrod code and prints the parsed abstract syntax
  ## tree using the `toTree` function.
  ##
  ## You can use this as a tool to explore the Nimrod's abstract syntax 
  ## tree and to discover what kind of nodes must be created to represent
  ## a certain expression/statement

macro dumpLisp*(s: stmt): stmt = echo s[1].lispRepr
  ## Accepts a block of nimrod code and prints the parsed abstract syntax
  ## tree using the `toLisp` function.
  ##
  ## see `dumpTree`

