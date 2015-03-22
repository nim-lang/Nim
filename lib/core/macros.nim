#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

include "system/inclrtl"

## This module contains the interface to the compiler's abstract syntax
## tree (`AST`:idx:). Macros operate on this tree.

## .. include:: ../doc/astspec.txt

type
  NimNodeKind* = enum
    nnkNone, nnkEmpty, nnkIdent, nnkSym,
    nnkType, nnkCharLit, nnkIntLit, nnkInt8Lit,
    nnkInt16Lit, nnkInt32Lit, nnkInt64Lit, nnkUIntLit, nnkUInt8Lit,
    nnkUInt16Lit, nnkUInt32Lit, nnkUInt64Lit, nnkFloatLit,
    nnkFloat32Lit, nnkFloat64Lit, nnkFloat128Lit, nnkStrLit, nnkRStrLit,
    nnkTripleStrLit, nnkNilLit, nnkMetaNode, nnkDotCall,
    nnkCommand, nnkCall, nnkCallStrLit, nnkInfix,
    nnkPrefix, nnkPostfix, nnkHiddenCallConv,
    nnkExprEqExpr,
    nnkExprColonExpr, nnkIdentDefs, nnkVarTuple,
    nnkPar, nnkObjConstr, nnkCurly, nnkCurlyExpr,
    nnkBracket, nnkBracketExpr, nnkPragmaExpr, nnkRange,
    nnkDotExpr, nnkCheckedFieldExpr, nnkDerefExpr, nnkIfExpr,
    nnkElifExpr, nnkElseExpr, nnkLambda, nnkDo, nnkAccQuoted,
    nnkTableConstr, nnkBind,
    nnkClosedSymChoice,
    nnkOpenSymChoice,
    nnkHiddenStdConv,
    nnkHiddenSubConv, nnkConv, nnkCast, nnkStaticExpr,
    nnkAddr, nnkHiddenAddr, nnkHiddenDeref, nnkObjDownConv,
    nnkObjUpConv, nnkChckRangeF, nnkChckRange64, nnkChckRange,
    nnkStringToCString, nnkCStringToString, nnkAsgn,
    nnkFastAsgn, nnkGenericParams, nnkFormalParams, nnkOfInherit,
    nnkImportAs, nnkProcDef, nnkMethodDef, nnkConverterDef,
    nnkMacroDef, nnkTemplateDef, nnkIteratorDef, nnkOfBranch,
    nnkElifBranch, nnkExceptBranch, nnkElse,
    nnkAsmStmt, nnkPragma, nnkPragmaBlock, nnkIfStmt, nnkWhenStmt,
    nnkForStmt, nnkParForStmt, nnkWhileStmt, nnkCaseStmt,
    nnkTypeSection, nnkVarSection, nnkLetSection, nnkConstSection,
    nnkConstDef, nnkTypeDef,
    nnkYieldStmt, nnkDefer, nnkTryStmt, nnkFinally, nnkRaiseStmt,
    nnkReturnStmt, nnkBreakStmt, nnkContinueStmt, nnkBlockStmt, nnkStaticStmt,
    nnkDiscardStmt, nnkStmtList,
    nnkImportStmt,
    nnkImportExceptStmt,
    nnkExportStmt,
    nnkExportExceptStmt,
    nnkFromStmt,
    nnkIncludeStmt,
    nnkBindStmt, nnkMixinStmt, nnkUsingStmt,
    nnkCommentStmt, nnkStmtListExpr, nnkBlockExpr,
    nnkStmtListType, nnkBlockType,
    nnkWith, nnkWithout,
    nnkTypeOfExpr, nnkObjectTy,
    nnkTupleTy, nnkTupleClassTy, nnkTypeClassTy, nnkStaticTy,
    nnkRecList, nnkRecCase, nnkRecWhen,
    nnkRefTy, nnkPtrTy, nnkVarTy,
    nnkConstTy, nnkMutableTy,
    nnkDistinctTy,
    nnkProcTy,
    nnkIteratorTy,         # iterator type
    nnkSharedTy,           # 'shared T'
    nnkEnumTy,
    nnkEnumFieldDef,
    nnkArglist, nnkPattern
    nnkReturnToken
  NimNodeKinds* = set[NimNodeKind]
  NimTypeKind* = enum
    ntyNone, ntyBool, ntyChar, ntyEmpty,
    ntyArrayConstr, ntyNil, ntyExpr, ntyStmt,
    ntyTypeDesc, ntyGenericInvocation, ntyGenericBody, ntyGenericInst,
    ntyGenericParam, ntyDistinct, ntyEnum, ntyOrdinal,
    ntyArray, ntyObject, ntyTuple, ntySet,
    ntyRange, ntyPtr, ntyRef, ntyVar,
    ntySequence, ntyProc, ntyPointer, ntyOpenArray,
    ntyString, ntyCString, ntyForward, ntyInt,
    ntyInt8, ntyInt16, ntyInt32, ntyInt64,
    ntyFloat, ntyFloat32, ntyFloat64, ntyFloat128,
    ntyUInt, ntyUInt8, ntyUInt16, ntyUInt32, ntyUInt64,
    ntyBigNum,
    ntyConst, ntyMutable, ntyVarargs,
    ntyIter,
    ntyError

  TNimTypeKinds* {.deprecated.} = set[NimTypeKind]
  NimSymKind* = enum
    nskUnknown, nskConditional, nskDynLib, nskParam,
    nskGenericParam, nskTemp, nskModule, nskType, nskVar, nskLet,
    nskConst, nskResult,
    nskProc, nskMethod, nskIterator, nskClosureIterator,
    nskConverter, nskMacro, nskTemplate, nskField,
    nskEnumField, nskForVar, nskLabel,
    nskStub

  TNimSymKinds* {.deprecated.} = set[NimSymKind]

type
  NimIdent* = object of RootObj
    ## represents a Nim identifier in the AST

  NimSymObj = object # hidden
  NimSym* = ref NimSymObj
    ## represents a Nim *symbol* in the compiler; a *symbol* is a looked-up
    ## *ident*.

{.deprecated: [TNimrodNodeKind: NimNodeKind, TNimNodeKinds: NimNodeKinds,
    TNimrodTypeKind: NimTypeKind, TNimrodSymKind: NimSymKind,
    TNimrodIdent: NimIdent, PNimrodSymbol: NimSym].}

const
  nnkLiterals* = {nnkCharLit..nnkNilLit}
  nnkCallKinds* = {nnkCall, nnkInfix, nnkPrefix, nnkPostfix, nnkCommand,
                   nnkCallStrLit}

proc `[]`*(n: NimNode, i: int): NimNode {.magic: "NChild", noSideEffect.}
  ## get `n`'s `i`'th child.

proc `[]=`*(n: NimNode, i: int, child: NimNode) {.magic: "NSetChild",
  noSideEffect.}
  ## set `n`'s `i`'th child to `child`.

proc `!`*(s: string): NimIdent {.magic: "StrToIdent", noSideEffect.}
  ## constructs an identifier from the string `s`

proc `$`*(i: NimIdent): string {.magic: "IdentToStr", noSideEffect.}
  ## converts a Nim identifier to a string

proc `$`*(s: NimSym): string {.magic: "IdentToStr", noSideEffect.}
  ## converts a Nim symbol to a string

proc `==`*(a, b: NimIdent): bool {.magic: "EqIdent", noSideEffect.}
  ## compares two Nim identifiers

proc `==`*(a, b: NimNode): bool {.magic: "EqNimrodNode", noSideEffect.}
  ## compares two Nim nodes

proc len*(n: NimNode): int {.magic: "NLen", noSideEffect.}
  ## returns the number of children of `n`.

proc add*(father, child: NimNode): NimNode {.magic: "NAdd", discardable,
  noSideEffect, locks: 0.}
  ## Adds the `child` to the `father` node. Returns the
  ## father node so that calls can be nested.

proc add*(father: NimNode, children: varargs[NimNode]): NimNode {.
  magic: "NAddMultiple", discardable, noSideEffect, locks: 0.}
  ## Adds each child of `children` to the `father` node.
  ## Returns the `father` node so that calls can be nested.

proc del*(father: NimNode, idx = 0, n = 1) {.magic: "NDel", noSideEffect.}
  ## deletes `n` children of `father` starting at index `idx`.

proc kind*(n: NimNode): NimNodeKind {.magic: "NKind", noSideEffect.}
  ## returns the `kind` of the node `n`.

proc intVal*(n: NimNode): BiggestInt {.magic: "NIntVal", noSideEffect.}
proc floatVal*(n: NimNode): BiggestFloat {.magic: "NFloatVal", noSideEffect.}
proc symbol*(n: NimNode): NimSym {.magic: "NSymbol", noSideEffect.}
proc ident*(n: NimNode): NimIdent {.magic: "NIdent", noSideEffect.}

proc getType*(n: NimNode): NimNode {.magic: "NGetType", noSideEffect.}
  ## with 'getType' you can access the node's `type`:idx:. A Nim type is
  ## mapped to a Nim AST too, so it's slightly confusing but it means the same
  ## API can be used to traverse types. Recursive types are flattened for you
  ## so there is no danger of infinite recursions during traversal. To
  ## resolve recursive types, you have to call 'getType' again. To see what
  ## kind of type it is, call `typeKind` on getType's result.

proc typeKind*(n: NimNode): NimTypeKind {.magic: "NGetType", noSideEffect.}
  ## Returns the type kind of the node 'n' that should represent a type, that
  ## means the node should have been obtained via `getType`.

proc strVal*(n: NimNode): string  {.magic: "NStrVal", noSideEffect.}

proc `intVal=`*(n: NimNode, val: BiggestInt) {.magic: "NSetIntVal", noSideEffect.}
proc `floatVal=`*(n: NimNode, val: BiggestFloat) {.magic: "NSetFloatVal", noSideEffect.}
proc `symbol=`*(n: NimNode, val: NimSym) {.magic: "NSetSymbol", noSideEffect.}
proc `ident=`*(n: NimNode, val: NimIdent) {.magic: "NSetIdent", noSideEffect.}
#proc `typ=`*(n: NimNode, typ: typedesc) {.magic: "NSetType".}
# this is not sound! Unfortunately forbidding 'typ=' is not enough, as you
# can easily do:
#   let bracket = semCheck([1, 2])
#   let fake = semCheck(2.0)
#   bracket[0] = fake  # constructs a mixed array with ints and floats!

proc `strVal=`*(n: NimNode, val: string) {.magic: "NSetStrVal", noSideEffect.}

proc newNimNode*(kind: NimNodeKind,
                 n: NimNode=nil): NimNode {.magic: "NNewNimNode", noSideEffect.}

proc copyNimNode*(n: NimNode): NimNode {.magic: "NCopyNimNode", noSideEffect.}
proc copyNimTree*(n: NimNode): NimNode {.magic: "NCopyNimTree", noSideEffect.}

proc error*(msg: string) {.magic: "NError", benign.}
  ## writes an error message at compile time

proc warning*(msg: string) {.magic: "NWarning", benign.}
  ## writes a warning message at compile time

proc hint*(msg: string) {.magic: "NHint", benign.}
  ## writes a hint message at compile time

proc newStrLitNode*(s: string): NimNode {.compileTime, noSideEffect.} =
  ## creates a string literal node from `s`
  result = newNimNode(nnkStrLit)
  result.strVal = s

proc newIntLitNode*(i: BiggestInt): NimNode {.compileTime.} =
  ## creates a int literal node from `i`
  result = newNimNode(nnkIntLit)
  result.intVal = i

proc newFloatLitNode*(f: BiggestFloat): NimNode {.compileTime.} =
  ## creates a float literal node from `f`
  result = newNimNode(nnkFloatLit)
  result.floatVal = f

proc newIdentNode*(i: NimIdent): NimNode {.compileTime.} =
  ## creates an identifier node from `i`
  result = newNimNode(nnkIdent)
  result.ident = i

proc newIdentNode*(i: string): NimNode {.compileTime.} =
  ## creates an identifier node from `i`
  result = newNimNode(nnkIdent)
  result.ident = !i

type
  BindSymRule* = enum    ## specifies how ``bindSym`` behaves
    brClosed,            ## only the symbols in current scope are bound
    brOpen,              ## open wrt overloaded symbols, but may be a single
                         ## symbol if not ambiguous (the rules match that of
                         ## binding in generics)
    brForceOpen          ## same as brOpen, but it will always be open even
                         ## if not ambiguous (this cannot be achieved with
                         ## any other means in the language currently)

{.deprecated: [TBindSymRule: BindSymRule].}

proc bindSym*(ident: string, rule: BindSymRule = brClosed): NimNode {.
              magic: "NBindSym", noSideEffect.}
  ## creates a node that binds `ident` to a symbol node. The bound symbol
  ## may be an overloaded symbol.
  ## If ``rule == brClosed`` either an ``nkClosedSymChoice`` tree is
  ## returned or ``nkSym`` if the symbol is not ambiguous.
  ## If ``rule == brOpen`` either an ``nkOpenSymChoice`` tree is
  ## returned or ``nkSym`` if the symbol is not ambiguous.
  ## If ``rule == brForceOpen`` always an ``nkOpenSymChoice`` tree is
  ## returned even if the symbol is not ambiguous.

proc genSym*(kind: NimSymKind = nskLet; ident = ""): NimNode {.
  magic: "NGenSym", noSideEffect.}
  ## generates a fresh symbol that is guaranteed to be unique. The symbol
  ## needs to occur in a declaration context.

proc callsite*(): NimNode {.magic: "NCallSite", benign.}
  ## returns the AST of the invocation expression that invoked this macro.

proc toStrLit*(n: NimNode): NimNode {.compileTime.} =
  ## converts the AST `n` to the concrete Nim code and wraps that
  ## in a string literal node
  return newStrLitNode(repr(n))

proc lineinfo*(n: NimNode): string {.magic: "NLineInfo", noSideEffect.}
  ## returns the position the node appears in the original source file
  ## in the form filename(line, col)

proc internalParseExpr(s: string): NimNode {.
  magic: "ParseExprToAst", noSideEffect.}

proc internalParseStmt(s: string): NimNode {.
  magic: "ParseStmtToAst", noSideEffect.}

proc internalErrorFlag*(): string {.magic: "NError", noSideEffect.}
  ## Some builtins set an error flag. This is then turned into a proper
  ## exception. **Note**: Ordinary application code should not call this.

proc parseExpr*(s: string): NimNode {.noSideEffect, compileTime.} =
  ## Compiles the passed string to its AST representation.
  ## Expects a single expression. Raises ``ValueError`` for parsing errors.
  result = internalParseExpr(s)
  let x = internalErrorFlag()
  if x.len > 0: raise newException(ValueError, x)

proc parseStmt*(s: string): NimNode {.noSideEffect, compileTime.} =
  ## Compiles the passed string to its AST representation.
  ## Expects one or more statements. Raises ``ValueError`` for parsing errors.
  result = internalParseStmt(s)
  let x = internalErrorFlag()
  if x.len > 0: raise newException(ValueError, x)

proc getAst*(macroOrTemplate: expr): NimNode {.magic: "ExpandToAst", noSideEffect.}
  ## Obtains the AST nodes returned from a macro or template invocation.
  ## Example:
  ##
  ## .. code-block:: nim
  ##
  ##   macro FooMacro() =
  ##     var ast = getAst(BarTemplate())

proc quote*(bl: stmt, op = "``"): NimNode {.magic: "QuoteAst", noSideEffect.}
  ## Quasi-quoting operator.
  ## Accepts an expression or a block and returns the AST that represents it.
  ## Within the quoted AST, you are able to interpolate NimNode expressions
  ## from the surrounding scope. If no operator is given, quoting is done using
  ## backticks. Otherwise, the given operator must be used as a prefix operator
  ## for any interpolated expression. The original meaning of the interpolation
  ## operator may be obtained by escaping it (by prefixing it with itself):
  ## e.g. `@` is escaped as `@@`, `@@` is escaped as `@@@` and so on.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##
  ##   macro check(ex: expr): stmt =
  ##     # this is a simplified version of the check macro from the
  ##     # unittest module.
  ##
  ##     # If there is a failed check, we want to make it easy for
  ##     # the user to jump to the faulty line in the code, so we
  ##     # get the line info here:
  ##     var info = ex.lineinfo
  ##
  ##     # We will also display the code string of the failed check:
  ##     var expString = ex.toStrLit
  ##
  ##     # Finally we compose the code to implement the check:
  ##     result = quote do:
  ##       if not `ex`:
  ##         echo `info` & ": Check failed: " & `expString`

proc expectKind*(n: NimNode, k: NimNodeKind) {.compileTime.} =
  ## checks that `n` is of kind `k`. If this is not the case,
  ## compilation aborts with an error message. This is useful for writing
  ## macros that check the AST that is passed to them.
  if n.kind != k: error("Expected a node of kind " & $k & ", got " & $n.kind)

proc expectMinLen*(n: NimNode, min: int) {.compileTime.} =
  ## checks that `n` has at least `min` children. If this is not the case,
  ## compilation aborts with an error message. This is useful for writing
  ## macros that check its number of arguments.
  if n.len < min: error("macro expects a node with " & $min & " children")

proc expectLen*(n: NimNode, len: int) {.compileTime.} =
  ## checks that `n` has exactly `len` children. If this is not the case,
  ## compilation aborts with an error message. This is useful for writing
  ## macros that check its number of arguments.
  if n.len != len: error("macro expects a node with " & $len & " children")

proc newCall*(theProc: NimNode,
              args: varargs[NimNode]): NimNode {.compileTime.} =
  ## produces a new call node. `theProc` is the proc that is called with
  ## the arguments ``args[0..]``.
  result = newNimNode(nnkCall)
  result.add(theProc)
  result.add(args)

proc newCall*(theProc: NimIdent,
              args: varargs[NimNode]): NimNode {.compileTime.} =
  ## produces a new call node. `theProc` is the proc that is called with
  ## the arguments ``args[0..]``.
  result = newNimNode(nnkCall)
  result.add(newIdentNode(theProc))
  result.add(args)

proc newCall*(theProc: string,
              args: varargs[NimNode]): NimNode {.compileTime.} =
  ## produces a new call node. `theProc` is the proc that is called with
  ## the arguments ``args[0..]``.
  result = newNimNode(nnkCall)
  result.add(newIdentNode(theProc))
  result.add(args)

proc newLit*(c: char): NimNode {.compileTime.} =
  ## produces a new character literal node.
  result = newNimNode(nnkCharLit)
  result.intVal = ord(c)

proc newLit*(i: BiggestInt): NimNode {.compileTime.} =
  ## produces a new integer literal node.
  result = newNimNode(nnkIntLit)
  result.intVal = i

proc newLit*(f: BiggestFloat): NimNode {.compileTime.} =
  ## produces a new float literal node.
  result = newNimNode(nnkFloatLit)
  result.floatVal = f

proc newLit*(s: string): NimNode {.compileTime.} =
  ## produces a new string literal node.
  result = newNimNode(nnkStrLit)
  result.strVal = s

proc nestList*(theProc: NimIdent,
               x: NimNode): NimNode {.compileTime.} =
  ## nests the list `x` into a tree of call expressions:
  ## ``[a, b, c]`` is transformed into ``theProc(a, theProc(c, d))``.
  var L = x.len
  result = newCall(theProc, x[L-2], x[L-1])
  for i in countdown(L-3, 0):
    # XXX the 'copyNimTree' here is necessary due to a bug in the evaluation
    # engine that would otherwise create an endless loop here. :-(
    # This could easily user code and so should be fixed in evals.nim somehow.
    result = newCall(theProc, x[i], copyNimTree(result))

proc treeRepr*(n: NimNode): string {.compileTime, benign.} =
  ## Convert the AST `n` to a human-readable tree-like string.
  ##
  ## See also `repr` and `lispRepr`.
  proc traverse(res: var string, level: int, n: NimNode) {.benign.} =
    for i in 0..level-1: res.add "  "
    res.add(($n.kind).substr(3))

    case n.kind
    of nnkEmpty: discard # same as nil node in this representation
    of nnkNilLit: res.add(" nil")
    of nnkCharLit..nnkInt64Lit: res.add(" " & $n.intVal)
    of nnkFloatLit..nnkFloat64Lit: res.add(" " & $n.floatVal)
    of nnkStrLit..nnkTripleStrLit: res.add(" " & $n.strVal)
    of nnkIdent: res.add(" !\"" & $n.ident & '"')
    of nnkSym: res.add(" \"" & $n.symbol & '"')
    of nnkNone: assert false
    else:
      for j in 0..n.len-1:
        res.add "\n"
        traverse(res, level + 1, n[j])

  result = ""
  traverse(result, 0, n)

proc lispRepr*(n: NimNode): string {.compileTime, benign.} =
  ## Convert the AST `n` to a human-readable lisp-like string,
  ##
  ## See also `repr` and `treeRepr`.

  result = ($n.kind).substr(3)
  add(result, "(")

  case n.kind
  of nnkEmpty: discard # same as nil node in this representation
  of nnkNilLit: add(result, "nil")
  of nnkCharLit..nnkInt64Lit: add(result, $n.intVal)
  of nnkFloatLit..nnkFloat64Lit: add(result, $n.floatVal)
  of nnkStrLit..nnkTripleStrLit: add(result, $n.strVal)
  of nnkIdent: add(result, "!\"" & $n.ident & '"')
  of nnkSym: add(result, $n.symbol)
  of nnkNone: assert false
  else:
    if n.len > 0:
      add(result, lispRepr(n[0]))
      for j in 1..n.len-1:
        add(result, ", ")
        add(result, lispRepr(n[j]))

  add(result, ")")

macro dumpTree*(s: stmt): stmt {.immediate.} = echo s.treeRepr
  ## Accepts a block of nim code and prints the parsed abstract syntax
  ## tree using the `toTree` function. Printing is done *at compile time*.
  ##
  ## You can use this as a tool to explore the Nimrod's abstract syntax
  ## tree and to discover what kind of nodes must be created to represent
  ## a certain expression/statement.

macro dumpLisp*(s: stmt): stmt {.immediate.} = echo s.lispRepr
  ## Accepts a block of nim code and prints the parsed abstract syntax
  ## tree using the `toLisp` function. Printing is done *at compile time*.
  ##
  ## See `dumpTree`.

macro dumpTreeImm*(s: stmt): stmt {.immediate, deprecated.} = echo s.treeRepr
  ## The ``immediate`` version of `dumpTree`.

macro dumpLispImm*(s: stmt): stmt {.immediate, deprecated.} = echo s.lispRepr
  ## The ``immediate`` version of `dumpLisp`.


proc newEmptyNode*(): NimNode {.compileTime, noSideEffect.} =
  ## Create a new empty node
  result = newNimNode(nnkEmpty)

proc newStmtList*(stmts: varargs[NimNode]): NimNode {.compileTime.}=
  ## Create a new statement list
  result = newNimNode(nnkStmtList).add(stmts)

proc newPar*(exprs: varargs[NimNode]): NimNode {.compileTime.}=
  ## Create a new parentheses-enclosed expression
  newNimNode(nnkPar).add(exprs)

proc newBlockStmt*(label, body: NimNode): NimNode {.compileTime.} =
  ## Create a new block statement with label
  return newNimNode(nnkBlockStmt).add(label, body)

proc newBlockStmt*(body: NimNode): NimNode {.compiletime.} =
  ## Create a new block: stmt
  return newNimNode(nnkBlockStmt).add(newEmptyNode(), body)

proc newVarStmt*(name, value: NimNode): NimNode {.compiletime.} =
  ## Create a new var stmt
  return newNimNode(nnkVarSection).add(
    newNimNode(nnkIdentDefs).add(name, newNimNode(nnkEmpty), value))

proc newLetStmt*(name, value: NimNode): NimNode {.compiletime.} =
  ## Create a new let stmt
  return newNimNode(nnkLetSection).add(
    newNimNode(nnkIdentDefs).add(name, newNimNode(nnkEmpty), value))

proc newConstStmt*(name, value: NimNode): NimNode {.compileTime.} =
  ## Create a new const stmt
  newNimNode(nnkConstSection).add(
    newNimNode(nnkConstDef).add(name, newNimNode(nnkEmpty), value))

proc newAssignment*(lhs, rhs: NimNode): NimNode {.compileTime.} =
  return newNimNode(nnkAsgn).add(lhs, rhs)

proc newDotExpr*(a, b: NimNode): NimNode {.compileTime.} =
  ## Create new dot expression
  ## a.dot(b) ->  `a.b`
  return newNimNode(nnkDotExpr).add(a, b)

proc newColonExpr*(a, b: NimNode): NimNode {.compileTime.} =
  ## Create new colon expression
  ## newColonExpr(a, b) ->  `a: b`
  newNimNode(nnkExprColonExpr).add(a, b)

proc newIdentDefs*(name, kind: NimNode;
                   default = newEmptyNode()): NimNode {.compileTime.} =
  ## Creates a new ``nnkIdentDefs`` node of a specific kind and value.
  ##
  ## ``nnkIdentDefs`` need to have at least three children, but they can have
  ## more: first comes a list of identifiers followed by a type and value
  ## nodes. This helper proc creates a three node subtree, the first subnode
  ## being a single identifier name. Both the ``kind`` node and ``default``
  ## (value) nodes may be empty depending on where the ``nnkIdentDefs``
  ## appears: tuple or object definitions will have an empty ``default`` node,
  ## ``let`` or ``var`` blocks may have an empty ``kind`` node if the
  ## identifier is being assigned a value. Example:
  ##
  ## .. code-block:: nim
  ##
  ##   var varSection = newNimNode(nnkVarSection).add(
  ##     newIdentDefs(ident("a"), ident("string")),
  ##     newIdentDefs(ident("b"), newEmptyNode(), newLit(3)))
  ##   # --> var
  ##   #       a: string
  ##   #       b = 3
  ##
  ## If you need to create multiple identifiers you need to use the lower level
  ## ``newNimNode``:
  ##
  ## .. code-block:: nim
  ##
  ##   result = newNimNode(nnkIdentDefs).add(
  ##     ident("a"), ident("b"), ident("c"), ident("string"),
  ##       newStrLitNode("Hello"))
  newNimNode(nnkIdentDefs).add(name, kind, default)

proc newNilLit*(): NimNode {.compileTime.} =
  ## New nil literal shortcut
  result = newNimNode(nnkNilLit)

proc high*(node: NimNode): int {.compileTime.} = len(node) - 1
  ## Return the highest index available for a node
proc last*(node: NimNode): NimNode {.compileTime.} = node[node.high]
  ## Return the last item in nodes children. Same as `node[node.high()]`


const
  RoutineNodes* = {nnkProcDef, nnkMethodDef, nnkDo, nnkLambda, nnkIteratorDef}
  AtomicNodes* = {nnkNone..nnkNilLit}
  CallNodes* = {nnkCall, nnkInfix, nnkPrefix, nnkPostfix, nnkCommand,
    nnkCallStrLit, nnkHiddenCallConv}

proc expectKind*(n: NimNode; k: set[NimNodeKind]) {.compileTime.} =
  assert n.kind in k, "Expected one of " & $k & ", got " & $n.kind

proc newProc*(name = newEmptyNode(); params: openArray[NimNode] = [newEmptyNode()];
    body: NimNode = newStmtList(), procType = nnkProcDef): NimNode {.compileTime.} =
  ## shortcut for creating a new proc
  ##
  ## The ``params`` array must start with the return type of the proc,
  ## followed by a list of IdentDefs which specify the params.
  assert procType in RoutineNodes
  result = newNimNode(procType).add(
    name,
    newEmptyNode(),
    newEmptyNode(),
    newNimNode(nnkFormalParams).add(params), ##params
    newEmptyNode(),  ## pragmas
    newEmptyNode(),
    body)

proc newIfStmt*(branches: varargs[tuple[cond, body: NimNode]]):
                NimNode {.compiletime.} =
  ## Constructor for ``if`` statements.
  ##
  ## .. code-block:: nim
  ##
  ##    newIfStmt(
  ##      (Ident, StmtList),
  ##      ...
  ##    )
  ##
  result = newNimNode(nnkIfStmt)
  for i in branches:
    result.add(newNimNode(nnkElifBranch).add(i.cond, i.body))


proc copyChildrenTo*(src, dest: NimNode) {.compileTime.}=
  ## Copy all children from `src` to `dest`
  for i in 0 .. < src.len:
    dest.add src[i].copyNimTree

template expectRoutine(node: NimNode): stmt =
  expectKind(node, RoutineNodes)

proc name*(someProc: NimNode): NimNode {.compileTime.} =
  someProc.expectRoutine
  result = someProc[0]
proc `name=`*(someProc: NimNode; val: NimNode) {.compileTime.} =
  someProc.expectRoutine
  someProc[0] = val

proc params*(someProc: NimNode): NimNode {.compileTime.} =
  someProc.expectRoutine
  result = someProc[3]
proc `params=`* (someProc: NimNode; params: NimNode) {.compileTime.}=
  someProc.expectRoutine
  assert params.kind == nnkFormalParams
  someProc[3] = params

proc pragma*(someProc: NimNode): NimNode {.compileTime.} =
  ## Get the pragma of a proc type
  ## These will be expanded
  someProc.expectRoutine
  result = someProc[4]
proc `pragma=`*(someProc: NimNode; val: NimNode){.compileTime.}=
  ## Set the pragma of a proc type
  someProc.expectRoutine
  assert val.kind in {nnkEmpty, nnkPragma}
  someProc[4] = val


template badNodeKind(k; f): stmt{.immediate.} =
  assert false, "Invalid node kind " & $k & " for macros.`" & $f & "`"

proc body*(someProc: NimNode): NimNode {.compileTime.} =
  case someProc.kind:
  of RoutineNodes:
    return someProc[6]
  of nnkBlockStmt, nnkWhileStmt:
    return someProc[1]
  of nnkForStmt:
    return someProc.last
  else:
    badNodeKind someProc.kind, "body"

proc `body=`*(someProc: NimNode, val: NimNode) {.compileTime.} =
  case someProc.kind
  of RoutineNodes:
    someProc[6] = val
  of nnkBlockStmt, nnkWhileStmt:
    someProc[1] = val
  of nnkForStmt:
    someProc[high(someProc)] = val
  else:
    badNodeKind someProc.kind, "body="

proc basename*(a: NimNode): NimNode {.compiletime, benign.}


proc `$`*(node: NimNode): string {.compileTime.} =
  ## Get the string of an identifier node
  case node.kind
  of nnkIdent:
    result = $node.ident
  of nnkPostfix:
    result = $node.basename.ident & "*"
  of nnkStrLit..nnkTripleStrLit:
    result = node.strVal
  of nnkSym:
    result = $node.symbol
  else:
    badNodeKind node.kind, "$"

proc ident*(name: string): NimNode {.compileTime,inline.} = newIdentNode(name)
  ## Create a new ident node from a string

iterator children*(n: NimNode): NimNode {.inline.}=
  for i in 0 .. high(n):
    yield n[i]

template findChild*(n: NimNode; cond: expr): NimNode {.
  immediate, dirty.} =
  ## Find the first child node matching condition (or nil).
  ##
  ## .. code-block:: nim
  ##   var res = findChild(n, it.kind == nnkPostfix and
  ##                          it.basename.ident == !"foo")
  block:
    var result: NimNode
    for it in n.children:
      if cond:
        result = it
        break
    result

proc insert*(a: NimNode; pos: int; b: NimNode) {.compileTime.} =
  ## Insert node B into A at pos
  if high(a) < pos:
    ## add some empty nodes first
    for i in high(a)..pos-2:
      a.add newEmptyNode()
    a.add b
  else:
    ## push the last item onto the list again
    ## and shift each item down to pos up one
    a.add(a[a.high])
    for i in countdown(high(a) - 2, pos):
      a[i + 1] = a[i]
    a[pos] = b

proc basename*(a: NimNode): NimNode =
  ## Pull an identifier from prefix/postfix expressions
  case a.kind
  of nnkIdent: return a
  of nnkPostfix, nnkPrefix: return a[1]
  else:
    quit "Do not know how to get basename of (" & treeRepr(a) & ")\n" & repr(a)

proc `basename=`*(a: NimNode; val: string) {.compileTime.}=
  case a.kind
  of nnkIdent: macros.`ident=`(a,  !val)
  of nnkPostfix, nnkPrefix: a[1] = ident(val)
  else:
    quit "Do not know how to get basename of (" & treeRepr(a) & ")\n" & repr(a)

proc postfix*(node: NimNode; op: string): NimNode {.compileTime.} =
  newNimNode(nnkPostfix).add(ident(op), node)

proc prefix*(node: NimNode; op: string): NimNode {.compileTime.} =
  newNimNode(nnkPrefix).add(ident(op), node)

proc infix*(a: NimNode; op: string;
            b: NimNode): NimNode {.compileTime.} =
  newNimNode(nnkInfix).add(ident(op), a, b)

proc unpackPostfix*(node: NimNode): tuple[node: NimNode; op: string] {.
  compileTime.} =
  node.expectKind nnkPostfix
  result = (node[0], $node[1])

proc unpackPrefix*(node: NimNode): tuple[node: NimNode; op: string] {.
  compileTime.} =
  node.expectKind nnkPrefix
  result = (node[0], $node[1])

proc unpackInfix*(node: NimNode): tuple[left: NimNode; op: string;
                                        right: NimNode] {.compileTime.} =
  assert node.kind == nnkInfix
  result = (node[0], $node[1], node[2])

proc copy*(node: NimNode): NimNode {.compileTime.} =
  ## An alias for copyNimTree().
  return node.copyNimTree()

proc cmpIgnoreStyle(a, b: cstring): int {.noSideEffect.} =
  proc toLower(c: char): char {.inline.} =
    if c in {'A'..'Z'}: result = chr(ord(c) + (ord('a') - ord('A')))
    else: result = c
  var i = 0
  var j = 0
  while true:
    while a[i] == '_': inc(i)
    while b[j] == '_': inc(j) # BUGFIX: typo
    var aa = toLower(a[i])
    var bb = toLower(b[j])
    result = ord(aa) - ord(bb)
    if result != 0 or aa == '\0': break
    inc(i)
    inc(j)

proc eqIdent* (a, b: string): bool = cmpIgnoreStyle(a, b) == 0
  ## Check if two idents are identical.

proc hasArgOfName* (params: NimNode; name: string): bool {.compiletime.}=
  ## Search nnkFormalParams for an argument.
  assert params.kind == nnkFormalParams
  for i in 1 .. <params.len:
    template node: expr = params[i]
    if name.eqIdent( $ node[0]):
      return true

proc addIdentIfAbsent*(dest: NimNode, ident: string) {.compiletime.} =
  ## Add ident to dest if it is not present. This is intended for use
  ## with pragmas.
  for node in dest.children:
    case node.kind
    of nnkIdent:
      if ident.eqIdent($node): return
    of nnkExprColonExpr:
      if ident.eqIdent($node[0]): return
    else: discard
  dest.add(ident(ident))

when not defined(booting):
  template emit*(e: static[string]): stmt =
    ## accepts a single string argument and treats it as nim code
    ## that should be inserted verbatim in the program
    ## Example:
    ##
    ## .. code-block:: nim
    ##   emit("echo " & '"' & "hello world".toUpper & '"')
    ##
    macro payload: stmt {.gensym.} =
      result = parseStmt(e)
    payload()
