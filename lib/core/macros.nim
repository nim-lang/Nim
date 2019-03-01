#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

include "system/inclrtl"
include "system/helpers"

## This module contains the interface to the compiler's abstract syntax
## tree (`AST`:idx:). Macros operate on this tree.
##
## See also:
## * `macros tutorial <https://nim-lang.github.io/Nim/tut3.html>`_
## * `macros section in Nim manual <https://nim-lang.github.io/Nim/manual.html#macros>`_

## .. include:: ../../doc/astspec.txt

# If you look for the implementation of the magic symbol
# ``{.magic: "Foo".}``, search for `mFoo` and `opcFoo`.

type
  NimNodeKind* = enum
    nnkNone, nnkEmpty, nnkIdent, nnkSym,
    nnkType, nnkCharLit, nnkIntLit, nnkInt8Lit,
    nnkInt16Lit, nnkInt32Lit, nnkInt64Lit, nnkUIntLit, nnkUInt8Lit,
    nnkUInt16Lit, nnkUInt32Lit, nnkUInt64Lit, nnkFloatLit,
    nnkFloat32Lit, nnkFloat64Lit, nnkFloat128Lit, nnkStrLit, nnkRStrLit,
    nnkTripleStrLit, nnkNilLit, nnkComesFrom, nnkDotCall,
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
    nnkReturnToken,
    nnkClosure,
    nnkGotoState,
    nnkState,
    nnkBreakState,
    nnkFuncDef,
    nnkTupleConstr

  NimNodeKinds* = set[NimNodeKind]
  NimTypeKind* = enum  # some types are no longer used, see ast.nim
    ntyNone, ntyBool, ntyChar, ntyEmpty,
    ntyAlias, ntyNil, ntyExpr, ntyStmt,
    ntyTypeDesc, ntyGenericInvocation, ntyGenericBody, ntyGenericInst,
    ntyGenericParam, ntyDistinct, ntyEnum, ntyOrdinal,
    ntyArray, ntyObject, ntyTuple, ntySet,
    ntyRange, ntyPtr, ntyRef, ntyVar,
    ntySequence, ntyProc, ntyPointer, ntyOpenArray,
    ntyString, ntyCString, ntyForward, ntyInt,
    ntyInt8, ntyInt16, ntyInt32, ntyInt64,
    ntyFloat, ntyFloat32, ntyFloat64, ntyFloat128,
    ntyUInt, ntyUInt8, ntyUInt16, ntyUInt32, ntyUInt64,
    ntyUnused0, ntyUnused1, ntyUnused2,
    ntyVarargs,
    ntyUncheckedArray,
    ntyError,
    ntyBuiltinTypeClass, ntyUserTypeClass, ntyUserTypeClassInst,
    ntyCompositeTypeClass, ntyInferred, ntyAnd, ntyOr, ntyNot,
    ntyAnything, ntyStatic, ntyFromExpr, ntyOpt, ntyVoid

  TNimTypeKinds* {.deprecated.} = set[NimTypeKind]
  NimSymKind* = enum
    nskUnknown, nskConditional, nskDynLib, nskParam,
    nskGenericParam, nskTemp, nskModule, nskType, nskVar, nskLet,
    nskConst, nskResult,
    nskProc, nskFunc, nskMethod, nskIterator,
    nskConverter, nskMacro, nskTemplate, nskField,
    nskEnumField, nskForVar, nskLabel,
    nskStub

  TNimSymKinds* {.deprecated.} = set[NimSymKind]

type
  NimIdent* = object of RootObj
    ## represents a Nim identifier in the AST. **Note**: This is only
    ## rarely useful, for identifier construction from a string
    ## use ``ident"abc"``.

  NimSymObj = object # hidden
  NimSym* {.deprecated.} = ref NimSymObj
    ## represents a Nim *symbol* in the compiler; a *symbol* is a looked-up
    ## *ident*.


const
  nnkLiterals* = {nnkCharLit..nnkNilLit}
  nnkCallKinds* = {nnkCall, nnkInfix, nnkPrefix, nnkPostfix, nnkCommand,
                   nnkCallStrLit}
  nnkPragmaCallKinds = {nnkExprColonExpr, nnkCall, nnkCallStrLit}

proc `!`*(s: string): NimIdent {.magic: "StrToIdent", noSideEffect, deprecated.}
  ## constructs an identifier from the string `s`
  ## **Deprecated since version 0.18.0**: Use ``ident`` or ``newIdentNode`` instead.

proc toNimIdent*(s: string): NimIdent {.magic: "StrToIdent", noSideEffect, deprecated.}
  ## constructs an identifier from the string `s`
  ## **Deprecated since version 0.18.1**; Use ``ident`` or ``newIdentNode`` instead.

proc `==`*(a, b: NimIdent): bool {.magic: "EqIdent", noSideEffect, deprecated.}
  ## compares two Nim identifiers
  ## **Deprecated since version 0.18.1**; Use ``==`` on ``NimNode`` instead.

proc `==`*(a, b: NimNode): bool {.magic: "EqNimrodNode", noSideEffect.}
  ## compares two Nim nodes

proc `==`*(a, b: NimSym): bool {.magic: "EqNimrodNode", noSideEffect, deprecated.}
  ## compares two Nim symbols
  ## **Deprecated since version 0.18.1**; Use ``==(NimNode, NimNode)`` instead.


proc sameType*(a, b: NimNode): bool {.magic: "SameNodeType", noSideEffect.} =
  ## compares two Nim nodes' types. Return true if the types are the same,
  ## eg. true when comparing alias with original type.
  discard

proc len*(n: NimNode): int {.magic: "NLen", noSideEffect.}
  ## returns the number of children of `n`.

proc `[]`*(n: NimNode, i: int): NimNode {.magic: "NChild", noSideEffect.}
  ## get `n`'s `i`'th child.

proc `[]`*(n: NimNode, i: BackwardsIndex): NimNode = n[n.len - i.int]
  ## get `n`'s `i`'th child.

template `^^`(n: NimNode, i: untyped): untyped =
  (when i is BackwardsIndex: n.len - int(i) else: int(i))

proc `[]`*[T, U](n: NimNode, x: HSlice[T, U]): seq[NimNode] =
  ## slice operation for NimNode.
  ## returns a seq of child of `n` who inclusive range [n[x.a], n[x.b]].
  let xa = n ^^ x.a
  let L = (n ^^ x.b) - xa + 1
  result = newSeq[NimNode](L)
  for i in 0..<L:
    result[i] = n[i + xa]

proc `[]=`*(n: NimNode, i: int, child: NimNode) {.magic: "NSetChild",
  noSideEffect.}
  ## set `n`'s `i`'th child to `child`.

proc `[]=`*(n: NimNode, i: BackwardsIndex, child: NimNode) =
  ## set `n`'s `i`'th child to `child`.
  n[n.len - i.int] = child

template `or`*(x, y: NimNode): NimNode =
  ## Evaluate ``x`` and when it is not an empty node, return
  ## it. Otherwise evaluate to ``y``. Can be used to chain several
  ## expressions to get the first expression that is not empty.
  ##
  ## .. code-block:: nim
  ##
  ##   let node = mightBeEmpty() or mightAlsoBeEmpty() or fallbackNode

  let arg = x
  if arg != nil and arg.kind != nnkEmpty:
    arg
  else:
    y

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

proc ident*(n: NimNode): NimIdent {.magic: "NIdent", noSideEffect, deprecated.} =
  ## **Deprecated since version 0.18.1**; All functionality is defined on ``NimNode``.

proc symbol*(n: NimNode): NimSym {.magic: "NSymbol", noSideEffect, deprecated.}
  ## **Deprecated since version 0.18.1**; All functionality is defined on ``NimNode``.

proc getImpl*(s: NimSym): NimNode {.magic: "GetImpl", noSideEffect, deprecated: "use `getImpl: NimNode -> NimNode` instead".}

when defined(nimSymKind):
  proc symKind*(symbol: NimNode): NimSymKind {.magic: "NSymKind", noSideEffect.}
  proc getImpl*(symbol: NimNode): NimNode {.magic: "GetImpl", noSideEffect.}
  proc strVal*(n: NimNode): string  {.magic: "NStrVal", noSideEffect.}
    ## retrieve the implementation of `symbol`. `symbol` can be a
    ## routine or a const.

  proc `$`*(i: NimIdent): string {.magic: "NStrVal", noSideEffect, deprecated.}
    ## converts a Nim identifier to a string
    ## **Deprecated since version 0.18.1**; Use ``strVal`` instead.

  proc `$`*(s: NimSym): string {.magic: "NStrVal", noSideEffect, deprecated.}
    ## converts a Nim symbol to a string
    ## **Deprecated since version 0.18.1**; Use ``strVal`` instead.

else: # bootstrapping substitute
  proc getImpl*(symbol: NimNode): NimNode =
    symbol.symbol.getImpl

  proc strValOld(n: NimNode): string {.magic: "NStrVal", noSideEffect.}

  proc `$`*(s: NimSym): string {.magic: "IdentToStr", noSideEffect.}

  proc `$`*(i: NimIdent): string {.magic: "IdentToStr", noSideEffect.}

  proc strVal*(n: NimNode): string =
    if n.kind == nnkIdent:
      $n.ident
    elif n.kind == nnkSym:
      $n.symbol
    else:
      n.strValOld

when defined(nimSymImplTransform):
  proc getImplTransformed*(symbol: NimNode): NimNode {.magic: "GetImplTransf", noSideEffect.}
    ## for a typed proc returns the AST after transformation pass

when defined(nimHasSymOwnerInMacro):
  proc owner*(sym: NimNode): NimNode {.magic: "SymOwner", noSideEffect.}
    ## accepts node of kind nnkSym and returns its owner's symbol.
    ## result is also mnde of kind nnkSym if owner exists otherwise
    ## nnkNilLit is returned

when defined(nimHasInstantiationOfInMacro):
  proc isInstantiationOf*(instanceProcSym, genProcSym: NimNode): bool {.magic: "SymIsInstantiationOf", noSideEffect.}
    ## check if proc symbol is instance of the generic proc symbol
    ## useful to check proc symbols against generic symbols
    ## returned by `bindSym`

proc getType*(n: NimNode): NimNode {.magic: "NGetType", noSideEffect.}
  ## with 'getType' you can access the node's `type`:idx:. A Nim type is
  ## mapped to a Nim AST too, so it's slightly confusing but it means the same
  ## API can be used to traverse types. Recursive types are flattened for you
  ## so there is no danger of infinite recursions during traversal. To
  ## resolve recursive types, you have to call 'getType' again. To see what
  ## kind of type it is, call `typeKind` on getType's result.

proc getType*(n: typedesc): NimNode {.magic: "NGetType", noSideEffect.}
  ## Returns the Nim type node for given type. This can be used to turn macro
  ## typedesc parameter into proper NimNode representing type, since typedesc
  ## are an exception in macro calls - they are not mapped implicitly to
  ## NimNode like any other arguments.

proc typeKind*(n: NimNode): NimTypeKind {.magic: "NGetType", noSideEffect.}
  ## Returns the type kind of the node 'n' that should represent a type, that
  ## means the node should have been obtained via ``getType``.

proc getTypeInst*(n: NimNode): NimNode {.magic: "NGetType", noSideEffect.} =
  ## Returns the `type`:idx: of a node in a form matching the way the
  ## type instance was declared in the code.
  runnableExamples:
    type
      Vec[N: static[int], T] = object
        arr: array[N, T]
      Vec4[T] = Vec[4, T]
      Vec4f = Vec4[float32]
    var a: Vec4f
    var b: Vec4[float32]
    var c: Vec[4, float32]
    macro dumpTypeInst(x: typed): untyped =
      newLit(x.getTypeInst.repr)
    doAssert(dumpTypeInst(a) == "Vec4f")
    doAssert(dumpTypeInst(b) == "Vec4[float32]")
    doAssert(dumpTypeInst(c) == "Vec[4, float32]")

proc getTypeInst*(n: typedesc): NimNode {.magic: "NGetType", noSideEffect.}
  ## Version of ``getTypeInst`` which takes a ``typedesc``.

proc getTypeImpl*(n: NimNode): NimNode {.magic: "NGetType", noSideEffect.} =
  ## Returns the `type`:idx: of a node in a form matching the implementation
  ## of the type.  Any intermediate aliases are expanded to arrive at the final
  ## type implementation.  You can instead use ``getImpl`` on a symbol if you
  ## want to find the intermediate aliases.
  runnableExamples:
    type
      Vec[N: static[int], T] = object
        arr: array[N, T]
      Vec4[T] = Vec[4, T]
      Vec4f = Vec4[float32]
    var a: Vec4f
    var b: Vec4[float32]
    var c: Vec[4, float32]
    macro dumpTypeImpl(x: typed): untyped =
      newLit(x.getTypeImpl.repr)
    let t = """
object
  arr: array[0 .. 3, float32]
"""
    doAssert(dumpTypeImpl(a) == t)
    doAssert(dumpTypeImpl(b) == t)
    doAssert(dumpTypeImpl(c) == t)

when defined(nimHasSignatureHashInMacro):
  proc signatureHash*(n: NimNode): string {.magic: "NSigHash", noSideEffect.}
    ## Returns a stable identifier derived from the signature of a symbol.
    ## The signature combines many factors such as the type of the symbol,
    ## the owning module of the symbol and others. The same identifier is
    ## used in the back-end to produce the mangled symbol name.

proc getTypeImpl*(n: typedesc): NimNode {.magic: "NGetType", noSideEffect.}
  ## Version of ``getTypeImpl`` which takes a ``typedesc``.

proc `intVal=`*(n: NimNode, val: BiggestInt) {.magic: "NSetIntVal", noSideEffect.}
proc `floatVal=`*(n: NimNode, val: BiggestFloat) {.magic: "NSetFloatVal", noSideEffect.}

proc `symbol=`*(n: NimNode, val: NimSym) {.magic: "NSetSymbol", noSideEffect, deprecated.}
  ## **Deprecated since version 0.18.1**; Generate a new ``NimNode`` with ``genSym`` instead.

proc `ident=`*(n: NimNode, val: NimIdent) {.magic: "NSetIdent", noSideEffect, deprecated.}
  ## **Deprecated since version 0.18.1**; Generate a new ``NimNode`` with ``ident(string)`` instead.

#proc `typ=`*(n: NimNode, typ: typedesc) {.magic: "NSetType".}
# this is not sound! Unfortunately forbidding 'typ=' is not enough, as you
# can easily do:
#   let bracket = semCheck([1, 2])
#   let fake = semCheck(2.0)
#   bracket[0] = fake  # constructs a mixed array with ints and floats!

proc `strVal=`*(n: NimNode, val: string) {.magic: "NSetStrVal", noSideEffect.}

proc newNimNode*(kind: NimNodeKind,
                 lineInfoFrom: NimNode = nil): NimNode
  {.magic: "NNewNimNode", noSideEffect.}
  ## Creates a new AST node of the specified kind.
  ##
  ## The ``lineInfoFrom`` parameter is used for line information when the
  ## produced code crashes. You should ensure that it is set to a node that
  ## you are transforming.

proc copyNimNode*(n: NimNode): NimNode {.magic: "NCopyNimNode", noSideEffect.}
proc copyNimTree*(n: NimNode): NimNode {.magic: "NCopyNimTree", noSideEffect.}

proc error*(msg: string, n: NimNode = nil) {.magic: "NError", benign.}
  ## writes an error message at compile time. The optional ``n: NimNode``
  ## parameter is used as the source for file and line number information in
  ## the compilation error message.

proc warning*(msg: string, n: NimNode = nil) {.magic: "NWarning", benign.}
  ## writes a warning message at compile time

proc hint*(msg: string, n: NimNode = nil) {.magic: "NHint", benign.}
  ## writes a hint message at compile time

proc newStrLitNode*(s: string): NimNode {.compileTime, noSideEffect.} =
  ## creates a string literal node from `s`
  result = newNimNode(nnkStrLit)
  result.strVal = s

proc newCommentStmtNode*(s: string): NimNode {.compileTime, noSideEffect.} =
  ## creates a comment statement node
  result = newNimNode(nnkCommentStmt)
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

proc newIdentNode*(i: string): NimNode {.magic: "StrToIdent", noSideEffect.}
  ## creates an identifier node from `i`. It is simply an alias for
  ## ``ident(string)``. Use that, it's shorter.

type
  BindSymRule* = enum    ## specifies how ``bindSym`` behaves
    brClosed,            ## only the symbols in current scope are bound
    brOpen,              ## open wrt overloaded symbols, but may be a single
                         ## symbol if not ambiguous (the rules match that of
                         ## binding in generics)
    brForceOpen          ## same as brOpen, but it will always be open even
                         ## if not ambiguous (this cannot be achieved with
                         ## any other means in the language currently)

proc bindSym*(ident: string | NimNode, rule: BindSymRule = brClosed): NimNode {.
              magic: "NBindSym", noSideEffect.}
  ## creates a node that binds `ident` to a symbol node. The bound symbol
  ## may be an overloaded symbol.
  ## if `ident` is a NimNode, it must have nkIdent kind.
  ## If ``rule == brClosed`` either an ``nkClosedSymChoice`` tree is
  ## returned or ``nkSym`` if the symbol is not ambiguous.
  ## If ``rule == brOpen`` either an ``nkOpenSymChoice`` tree is
  ## returned or ``nkSym`` if the symbol is not ambiguous.
  ## If ``rule == brForceOpen`` always an ``nkOpenSymChoice`` tree is
  ## returned even if the symbol is not ambiguous.
  ##
  ## experimental feature:
  ## use {.experimental: "dynamicBindSym".} to activate it
  ## if called from template / regular code, `ident` and `rule` must be
  ## constant expression / literal value.
  ## if called from macros / compile time procs / static blocks,
  ## `ident` and `rule` can be VM computed value.

proc genSym*(kind: NimSymKind = nskLet; ident = ""): NimNode {.
  magic: "NGenSym", noSideEffect.}
  ## generates a fresh symbol that is guaranteed to be unique. The symbol
  ## needs to occur in a declaration context.

proc callsite*(): NimNode {.magic: "NCallSite", benign,
  deprecated: "use varargs[untyped] in the macro prototype instead".}
  ## returns the AST of the invocation expression that invoked this macro.
  ## **Deprecated since version 0.18.1**.

proc toStrLit*(n: NimNode): NimNode {.compileTime.} =
  ## converts the AST `n` to the concrete Nim code and wraps that
  ## in a string literal node
  return newStrLitNode(repr(n))

type
  LineInfo* = object
    filename*: string
    line*,column*: int

proc `$`*(arg: Lineinfo): string =
  # BUG: without `result = `, gives compile error
  result = lineInfoToString(arg.filename, arg.line, arg.column)

#proc lineinfo*(n: NimNode): LineInfo {.magic: "NLineInfo", noSideEffect.}
  ## returns the position the node appears in the original source file
  ## in the form filename(line, col)

proc getLine(arg: NimNode): int {.magic: "NLineInfo", noSideEffect.}
proc getColumn(arg: NimNode): int {.magic: "NLineInfo", noSideEffect.}
proc getFile(arg: NimNode): string {.magic: "NLineInfo", noSideEffect.}

proc copyLineInfo*(arg: NimNode, info: NimNode) {.magic: "NLineInfo", noSideEffect.}
  ## copy lineinfo from info node

proc lineInfoObj*(n: NimNode): LineInfo {.compileTime.} =
  ## returns ``LineInfo`` of ``n``, using absolute path for ``filename``
  result.filename = n.getFile
  result.line = n.getLine
  result.column = n.getColumn

proc lineInfo*(arg: NimNode): string {.compileTime.} =
  $arg.lineInfoObj

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

proc getAst*(macroOrTemplate: untyped): NimNode {.magic: "ExpandToAst", noSideEffect.}
  ## Obtains the AST nodes returned from a macro or template invocation.
  ## Example:
  ##
  ## .. code-block:: nim
  ##
  ##   macro FooMacro() =
  ##     var ast = getAst(BarTemplate())

proc quote*(bl: typed, op = "``"): NimNode {.magic: "QuoteAst", noSideEffect.}
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
  ##   macro check(ex: untyped): typed =
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
  if n.kind != k: error("Expected a node of kind " & $k & ", got " & $n.kind, n)

proc expectMinLen*(n: NimNode, min: int) {.compileTime.} =
  ## checks that `n` has at least `min` children. If this is not the case,
  ## compilation aborts with an error message. This is useful for writing
  ## macros that check its number of arguments.
  if n.len < min: error("macro expects a node with " & $min & " children", n)

proc expectLen*(n: NimNode, len: int) {.compileTime.} =
  ## checks that `n` has exactly `len` children. If this is not the case,
  ## compilation aborts with an error message. This is useful for writing
  ## macros that check its number of arguments.
  if n.len != len: error("macro expects a node with " & $len & " children", n)

proc expectLen*(n: NimNode, min, max: int) {.compileTime.} =
  ## checks that `n` has a number of children in the range ``min..max``.
  ## If this is not the case, compilation aborts with an error message.
  ## This is useful for writing macros that check its number of arguments.
  if n.len < min or n.len > max:
    error("macro expects a node with " & $min & ".." & $max " children", n)

proc newTree*(kind: NimNodeKind,
              children: varargs[NimNode]): NimNode {.compileTime.} =
  ## produces a new node with children.
  result = newNimNode(kind)
  result.add(children)

proc newCall*(theProc: NimNode,
              args: varargs[NimNode]): NimNode {.compileTime.} =
  ## produces a new call node. `theProc` is the proc that is called with
  ## the arguments ``args[0..]``.
  result = newNimNode(nnkCall)
  result.add(theProc)
  result.add(args)

proc newCall*(theProc: NimIdent,
              args: varargs[NimNode]): NimNode {.compileTime, deprecated.} =
  ## produces a new call node. `theProc` is the proc that is called with
  ## the arguments ``args[0..]``.
  ## **Deprecated since version 0.18.1**; Use ``newCall(string, ...)``,
  ## or ``newCall(NimNode, ...)`` instead.
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

proc newLit*(i: int): NimNode {.compileTime.} =
  ## produces a new integer literal node.
  result = newNimNode(nnkIntLit)
  result.intVal = i

proc newLit*(i: int8): NimNode {.compileTime.} =
  ## produces a new integer literal node.
  result = newNimNode(nnkInt8Lit)
  result.intVal = i

proc newLit*(i: int16): NimNode {.compileTime.} =
  ## produces a new integer literal node.
  result = newNimNode(nnkInt16Lit)
  result.intVal = i

proc newLit*(i: int32): NimNode {.compileTime.} =
  ## produces a new integer literal node.
  result = newNimNode(nnkInt32Lit)
  result.intVal = i

proc newLit*(i: int64): NimNode {.compileTime.} =
  ## produces a new integer literal node.
  result = newNimNode(nnkInt64Lit)
  result.intVal = i

proc newLit*(i: uint): NimNode {.compileTime.} =
  ## produces a new unsigned integer literal node.
  result = newNimNode(nnkUIntLit)
  result.intVal = BiggestInt(i)

proc newLit*(i: uint8): NimNode {.compileTime.} =
  ## produces a new unsigned integer literal node.
  result = newNimNode(nnkUInt8Lit)
  result.intVal = BiggestInt(i)

proc newLit*(i: uint16): NimNode {.compileTime.} =
  ## produces a new unsigned integer literal node.
  result = newNimNode(nnkUInt16Lit)
  result.intVal = BiggestInt(i)

proc newLit*(i: uint32): NimNode {.compileTime.} =
  ## produces a new unsigned integer literal node.
  result = newNimNode(nnkUInt32Lit)
  result.intVal = BiggestInt(i)

proc newLit*(i: uint64): NimNode {.compileTime.} =
  ## produces a new unsigned integer literal node.
  result = newNimNode(nnkUInt64Lit)
  result.intVal = BiggestInt(i)

proc newLit*(b: bool): NimNode {.compileTime.} =
  ## produces a new boolean literal node.
  result = if b: bindSym"true" else: bindSym"false"

when false:
  # the float type is not really a distinct type as described in https://github.com/nim-lang/Nim/issues/5875
  proc newLit*(f: float): NimNode {.compileTime.} =
    ## produces a new float literal node.
    result = newNimNode(nnkFloatLit)
    result.floatVal = f

proc newLit*(f: float32): NimNode {.compileTime.} =
  ## produces a new float literal node.
  result = newNimNode(nnkFloat32Lit)
  result.floatVal = f

proc newLit*(f: float64): NimNode {.compileTime.} =
  ## produces a new float literal node.
  result = newNimNode(nnkFloat64Lit)
  result.floatVal = f

when compiles(float128):
  proc newLit*(f: float128): NimNode {.compileTime.} =
    ## produces a new float literal node.
    result = newNimNode(nnkFloat128Lit)
    result.floatVal = f

proc newLit*(arg: enum): NimNode {.compileTime.} =
  result = newCall(
    arg.type.getTypeInst[1],
    newLit(int(arg))
  )

proc newLit*[N,T](arg: array[N,T]): NimNode {.compileTime.}
proc newLit*[T](arg: seq[T]): NimNode {.compileTime.}
proc newLit*[T](s: set[T]): NimNode {.compileTime.}
proc newLit*(arg: tuple): NimNode {.compileTime.}

proc newLit*(arg: object): NimNode {.compileTime.} =
  result = nnkObjConstr.newTree(arg.type.getTypeInst[1])
  for a, b in arg.fieldPairs:
    result.add nnkExprColonExpr.newTree( newIdentNode(a), newLit(b) )

proc newLit*[N,T](arg: array[N,T]): NimNode {.compileTime.} =
  result = nnkBracket.newTree
  for x in arg:
    result.add newLit(x)

proc newLit*[T](arg: seq[T]): NimNode {.compileTime.} =
  var bracket = nnkBracket.newTree
  for x in arg:
    bracket.add newLit(x)

  result = nnkCall.newTree(
    nnkBracketExpr.newTree(
      nnkAccQuoted.newTree( bindSym"@" ),
      getTypeInst( bindSym"T" )
    ),
    bracket
  )

proc newLit*[T](s: set[T]): NimNode {.compileTime.} =
  result = nnkCurly.newTree
  for x in s:
    result.add newLit(x)

proc newLit*(arg: tuple): NimNode {.compileTime.} =
  result = nnkPar.newTree
  for a,b in arg.fieldPairs:
    result.add nnkExprColonExpr.newTree(newIdentNode(a), newLit(b))

proc newLit*(s: string): NimNode {.compileTime.} =
  ## produces a new string literal node.
  result = newNimNode(nnkStrLit)
  result.strVal = s

proc nestList*(op: NimNode; pack: NimNode): NimNode {.compileTime.} =
  ## nests the list `pack` into a tree of call expressions:
  ## ``[a, b, c]`` is transformed into ``op(a, op(c, d))``.
  ## This is also known as fold expression.
  if pack.len < 1:
    error("`nestList` expects a node with at least 1 child")
  result = pack[^1]
  for i in countdown(pack.len - 2, 0):
    result = newCall(op, pack[i], result)

proc nestList*(op: NimNode; pack: NimNode; init: NimNode): NimNode {.compileTime.} =
  ## nests the list `pack` into a tree of call expressions:
  ## ``[a, b, c]`` is transformed into ``op(a, op(c, d))``.
  ## This is also known as fold expression.
  result = init
  for i in countdown(pack.len - 1, 0):
    result = newCall(op, pack[i], result)

proc nestList*(theProc: NimIdent, x: NimNode): NimNode {.compileTime, deprecated.} =
  ## **Deprecated since version 0.18.1**; Use one of ``nestList(NimNode, ...)`` instead.
  var L = x.len
  result = newCall(theProc, x[L-2], x[L-1])
  for i in countdown(L-3, 0):
    result = newCall(theProc, x[i], result)

proc treeTraverse(n: NimNode; res: var string; level = 0; isLisp = false, indented = false) {.benign.} =
  if level > 0:
    if indented:
      res.add("\n")
      for i in 0 .. level-1:
        if isLisp:
          res.add(" ")          # dumpLisp indentation
        else:
          res.add("  ")         # dumpTree indentation
    else:
      res.add(" ")

  if isLisp:
    res.add("(")
  res.add(($n.kind).substr(3))

  case n.kind
  of nnkEmpty, nnkNilLit:
    discard # same as nil node in this representation
  of nnkCharLit .. nnkInt64Lit:
    res.add(" " & $n.intVal)
  of nnkFloatLit .. nnkFloat64Lit:
    res.add(" " & $n.floatVal)
  of nnkStrLit .. nnkTripleStrLit, nnkCommentStmt, nnkIdent, nnkSym:
    res.add(" " & $n.strVal.newLit.repr)
  of nnkNone:
    assert false
  else:
    for j in 0 .. n.len-1:
      n[j].treeTraverse(res, level+1, isLisp, indented)

  if isLisp:
    res.add(")")

proc treeRepr*(n: NimNode): string {.compileTime, benign.} =
  ## Convert the AST `n` to a human-readable tree-like string.
  ##
  ## See also `repr`, `lispRepr`, and `astGenRepr`.
  n.treeTraverse(result, isLisp = false, indented = true)

proc lispRepr*(n: NimNode; indented = false): string {.compileTime, benign.} =
  ## Convert the AST ``n`` to a human-readable lisp-like string.
  ##
  ## See also ``repr``, ``treeRepr``, and ``astGenRepr``.
  n.treeTraverse(result, isLisp = true, indented = indented)

proc astGenRepr*(n: NimNode): string {.compileTime, benign.} =
  ## Convert the AST ``n`` to the code required to generate that AST.
  ##
  ## See also ``repr``, ``treeRepr``, and ``lispRepr``.

  const
    NodeKinds = {nnkEmpty, nnkIdent, nnkSym, nnkNone, nnkCommentStmt}
    LitKinds = {nnkCharLit..nnkInt64Lit, nnkFloatLit..nnkFloat64Lit, nnkStrLit..nnkTripleStrLit}

  proc traverse(res: var string, level: int, n: NimNode) {.benign.} =
    for i in 0..level-1: res.add "  "
    if n.kind in NodeKinds:
      res.add("new" & ($n.kind).substr(3) & "Node(")
    elif n.kind in LitKinds:
      res.add("newLit(")
    elif n.kind == nnkNilLit:
      res.add("newNilLit()")
    else:
      res.add($n.kind)

    case n.kind
    of nnkEmpty, nnkNilLit: discard
    of nnkCharLit: res.add("'" & $chr(n.intVal) & "'")
    of nnkIntLit..nnkInt64Lit: res.add($n.intVal)
    of nnkFloatLit..nnkFloat64Lit: res.add($n.floatVal)
    of nnkStrLit..nnkTripleStrLit, nnkCommentStmt, nnkIdent, nnkSym:
      res.add(n.strVal.newLit.repr)
    of nnkNone: assert false
    else:
      res.add(".newTree(")
      for j in 0..<n.len:
        res.add "\n"
        traverse(res, level + 1, n[j])
        if j != n.len-1:
          res.add(",")

      res.add("\n")
      for i in 0..level-1: res.add "  "
      res.add(")")

    if n.kind in NodeKinds+LitKinds:
      res.add(")")

  result = ""
  traverse(result, 0, n)

macro dumpTree*(s: untyped): untyped = echo s.treeRepr
  ## Accepts a block of nim code and prints the parsed abstract syntax
  ## tree using the ``treeRepr`` proc. Printing is done *at compile time*.
  ##
  ## You can use this as a tool to explore the Nim's abstract syntax
  ## tree and to discover what kind of nodes must be created to represent
  ## a certain expression/statement.
  ##
  ## For example:
  ##
  ## .. code-block:: nim
  ##    dumpTree:
  ##      echo "Hello, World!"
  ##
  ## Outputs:
  ##
  ## .. code-block::
  ##    StmtList
  ##      Command
  ##        Ident "echo"
  ##        StrLit "Hello, World!"
  ##
  ## Also see ``dumpAstGen`` and ``dumpLisp``.

macro dumpLisp*(s: untyped): untyped = echo s.lispRepr(indented = true)
  ## Accepts a block of nim code and prints the parsed abstract syntax
  ## tree using the ``lispRepr`` proc. Printing is done *at compile time*.
  ##
  ## You can use this as a tool to explore the Nim's abstract syntax
  ## tree and to discover what kind of nodes must be created to represent
  ## a certain expression/statement.
  ##
  ## For example:
  ##
  ## .. code-block:: nim
  ##    dumpLisp:
  ##      echo "Hello, World!"
  ##
  ## Outputs:
  ##
  ## .. code-block::
  ##    (StmtList
  ##     (Command
  ##      (Ident "echo")
  ##      (StrLit "Hello, World!")))
  ##
  ## Also see ``dumpAstGen`` and ``dumpTree``.

macro dumpAstGen*(s: untyped): untyped = echo s.astGenRepr
  ## Accepts a block of nim code and prints the parsed abstract syntax
  ## tree using the ``astGenRepr`` proc. Printing is done *at compile time*.
  ##
  ## You can use this as a tool to write macros quicker by writing example
  ## outputs and then copying the snippets into the macro for modification.
  ##
  ## For example:
  ##
  ## .. code-block:: nim
  ##    dumpAstGen:
  ##      echo "Hello, World!"
  ##
  ## Outputs:
  ##
  ## .. code-block:: nim
  ##    nnkStmtList.newTree(
  ##      nnkCommand.newTree(
  ##        newIdentNode("echo"),
  ##        newLit("Hello, World!")
  ##      )
  ##    )
  ##
  ## Also see ``dumpTree`` and ``dumpLisp``.

macro dumpTreeImm*(s: untyped): untyped {.deprecated.} = echo s.treeRepr
  ## Deprecated. Use `dumpTree` instead.

macro dumpLispImm*(s: untyped): untyped {.deprecated.} = echo s.lispRepr
  ## Deprecated. Use `dumpLisp` instead.

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

proc last*(node: NimNode): NimNode {.compileTime.} = node[node.len-1]
  ## Return the last item in nodes children. Same as `node[^1]`


const
  RoutineNodes* = {nnkProcDef, nnkFuncDef, nnkMethodDef, nnkDo, nnkLambda,
                   nnkIteratorDef, nnkTemplateDef, nnkConverterDef}
  AtomicNodes* = {nnkNone..nnkNilLit}
  CallNodes* = {nnkCall, nnkInfix, nnkPrefix, nnkPostfix, nnkCommand,
    nnkCallStrLit, nnkHiddenCallConv}

proc expectKind*(n: NimNode; k: set[NimNodeKind]) {.compileTime.} =
  ## checks that `n` is of kind `k`. If this is not the case,
  ## compilation aborts with an error message. This is useful for writing
  ## macros that check the AST that is passed to them.
  if n.kind notin k: error("Expected one of " & $k & ", got " & $n.kind, n)

proc newProc*(name = newEmptyNode(); params: openArray[NimNode] = [newEmptyNode()];
    body: NimNode = newStmtList(), procType = nnkProcDef): NimNode {.compileTime.} =
  ## shortcut for creating a new proc
  ##
  ## The ``params`` array must start with the return type of the proc,
  ## followed by a list of IdentDefs which specify the params.
  if procType notin RoutineNodes:
    error("Expected one of " & $RoutineNodes & ", got " & $procType)
  result = newNimNode(procType).add(
    name,
    newEmptyNode(),
    newEmptyNode(),
    newNimNode(nnkFormalParams).add(params),
    newEmptyNode(),  # pragmas
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
    result.add(newTree(nnkElifBranch, i.cond, i.body))

proc newEnum*(name: NimNode, fields: openArray[NimNode],
              public, pure: bool): NimNode {.compileTime.} =

  ## Creates a new enum. `name` must be an ident. Fields are allowed to be
  ## either idents or EnumFieldDef
  ##
  ## .. code-block:: nim
  ##
  ##    newEnum(
  ##      name    = ident("Colors"),
  ##      fields  = [ident("Blue"), ident("Red")],
  ##      public  = true, pure = false)
  ##
  ##    # type Colors* = Blue Red
  ##

  expectKind name, nnkIdent
  if len(fields) < 1:
    error("Enum must contain at least one field")
  for field in fields:
    expectKind field, {nnkIdent, nnkEnumFieldDef}

  let enumBody = newNimNode(nnkEnumTy).add(newEmptyNode()).add(fields)
  var typeDefArgs = [name, newEmptyNode(), enumBody]

  if public:
    let postNode = newNimNode(nnkPostfix).add(
      newIdentNode("*"), typeDefArgs[0])

    typeDefArgs[0] = postNode

  if pure:
    let pragmaNode = newNimNode(nnkPragmaExpr).add(
      typeDefArgs[0],
      add(newNimNode(nnkPragma), newIdentNode("pure")))

    typeDefArgs[0] = pragmaNode

  let
    typeDef   = add(newNimNode(nnkTypeDef), typeDefArgs)
    typeSect  = add(newNimNode(nnkTypeSection), typeDef)

  return typeSect

proc copyChildrenTo*(src, dest: NimNode) {.compileTime.}=
  ## Copy all children from `src` to `dest`
  for i in 0 ..< src.len:
    dest.add src[i].copyNimTree

template expectRoutine(node: NimNode) =
  expectKind(node, RoutineNodes)

proc name*(someProc: NimNode): NimNode {.compileTime.} =
  someProc.expectRoutine
  result = someProc[0]
  if result.kind == nnkPostfix:
    if result[1].kind == nnkAccQuoted:
      result = result[1][0]
    else:
      result = result[1]
  elif result.kind == nnkAccQuoted:
    result = result[0]

proc `name=`*(someProc: NimNode; val: NimNode) {.compileTime.} =
  someProc.expectRoutine
  if someProc[0].kind == nnkPostfix:
    someProc[0][1] = val
  else: someProc[0] = val

proc params*(someProc: NimNode): NimNode {.compileTime.} =
  someProc.expectRoutine
  result = someProc[3]
proc `params=`* (someProc: NimNode; params: NimNode) {.compileTime.}=
  someProc.expectRoutine
  expectKind(params, nnkFormalParams)
  someProc[3] = params

proc pragma*(someProc: NimNode): NimNode {.compileTime.} =
  ## Get the pragma of a proc type
  ## These will be expanded
  someProc.expectRoutine
  result = someProc[4]
proc `pragma=`*(someProc: NimNode; val: NimNode){.compileTime.}=
  ## Set the pragma of a proc type
  someProc.expectRoutine
  expectKind(val, {nnkEmpty, nnkPragma})
  someProc[4] = val

proc addPragma*(someProc, pragma: NimNode) {.compileTime.} =
  ## Adds pragma to routine definition
  someProc.expectRoutine
  var pragmaNode = someProc.pragma
  if pragmaNode.isNil or pragmaNode.kind == nnkEmpty:
    pragmaNode = newNimNode(nnkPragma)
    someProc.pragma = pragmaNode
  pragmaNode.add(pragma)

template badNodeKind(n, f) =
  error("Invalid node kind " & $n.kind & " for macros.`" & $f & "`", n)

proc body*(someProc: NimNode): NimNode {.compileTime.} =
  case someProc.kind:
  of RoutineNodes:
    return someProc[6]
  of nnkBlockStmt, nnkWhileStmt:
    return someProc[1]
  of nnkForStmt:
    return someProc.last
  else:
    badNodeKind someProc, "body"

proc `body=`*(someProc: NimNode, val: NimNode) {.compileTime.} =
  case someProc.kind
  of RoutineNodes:
    someProc[6] = val
  of nnkBlockStmt, nnkWhileStmt:
    someProc[1] = val
  of nnkForStmt:
    someProc[len(someProc)-1] = val
  else:
    badNodeKind someProc, "body="

proc basename*(a: NimNode): NimNode {.compiletime, benign.}

proc `$`*(node: NimNode): string {.compileTime.} =
  ## Get the string of an identifier node
  case node.kind
  of nnkPostfix:
    result = node.basename.strVal & "*"
  of nnkStrLit..nnkTripleStrLit, nnkCommentStmt, nnkSym, nnkIdent:
    result = node.strVal
  of nnkOpenSymChoice, nnkClosedSymChoice:
    result = $node[0]
  of nnkAccQuoted:
    result = $node[0]
  else:
    badNodeKind node, "$"

proc ident*(name: string): NimNode {.magic: "StrToIdent", noSideEffect.}
  ## Create a new ident node from a string

iterator items*(n: NimNode): NimNode {.inline.} =
  ## Iterates over the children of the NimNode ``n``.
  for i in 0 ..< n.len:
    yield n[i]

iterator pairs*(n: NimNode): (int, NimNode) {.inline.} =
  ## Iterates over the children of the NimNode ``n`` and its indices.
  for i in 0 ..< n.len:
    yield (i, n[i])

iterator children*(n: NimNode): NimNode {.inline.} =
  ## Iterates over the children of the NimNode ``n``.
  for i in 0 ..< n.len:
    yield n[i]

template findChild*(n: NimNode; cond: untyped): NimNode {.dirty.} =
  ## Find the first child node matching condition (or nil).
  ##
  ## .. code-block:: nim
  ##   var res = findChild(n, it.kind == nnkPostfix and
  ##                          it.basename.ident == toNimIdent"foo")
  block:
    var res: NimNode
    for it in n.children:
      if cond:
        res = it
        break
    res

proc insert*(a: NimNode; pos: int; b: NimNode) {.compileTime.} =
  ## Insert node B into A at pos
  if len(a)-1 < pos:
    ## add some empty nodes first
    for i in len(a)-1..pos-2:
      a.add newEmptyNode()
    a.add b
  else:
    ## push the last item onto the list again
    ## and shift each item down to pos up one
    a.add(a[a.len-1])
    for i in countdown(len(a) - 3, pos):
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
  of nnkIdent: macros.`ident=`(a, toNimIdent val)
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
  result = (node[1], $node[0])

proc unpackPrefix*(node: NimNode): tuple[node: NimNode; op: string] {.
  compileTime.} =
  node.expectKind nnkPrefix
  result = (node[1], $node[0])

proc unpackInfix*(node: NimNode): tuple[left: NimNode; op: string;
                                        right: NimNode] {.compileTime.} =
  expectKind(node, nnkInfix)
  result = (node[1], $node[0], node[2])

proc copy*(node: NimNode): NimNode {.compileTime.} =
  ## An alias for copyNimTree().
  return node.copyNimTree()

when defined(nimVmEqIdent):
  proc eqIdent*(a: string; b: string): bool {.magic: "EqIdent", noSideEffect.}
    ## Style insensitive comparison.

  proc eqIdent*(a: NimNode; b: string): bool {.magic: "EqIdent", noSideEffect.}
    ## Style insensitive comparison.
    ## ``a`` can be an identifier or a symbol.

  proc eqIdent*(a: string; b: NimNode): bool {.magic: "EqIdent", noSideEffect.}
    ## Style insensitive comparison.
    ## ``b`` can be an identifier or a symbol.

  proc eqIdent*(a: NimNode; b: NimNode): bool {.magic: "EqIdent", noSideEffect.}
    ## Style insensitive comparison.
    ## ``a`` and ``b`` can be an identifier or a symbol.

else:
  # this procedure is optimized for native code, it should not be compiled to nimVM bytecode.
  proc cmpIgnoreStyle(a, b: cstring): int {.noSideEffect.} =
    proc toLower(c: char): char {.inline.} =
      if c in {'A'..'Z'}: result = chr(ord(c) + (ord('a') - ord('A')))
      else: result = c
    var i = 0
    var j = 0
    # first char is case sensitive
    if a[0] != b[0]: return 1
    while true:
      while a[i] == '_': inc(i)
      while b[j] == '_': inc(j) # BUGFIX: typo
      var aa = toLower(a[i])
      var bb = toLower(b[j])
      result = ord(aa) - ord(bb)
      if result != 0 or aa == '\0': break
      inc(i)
      inc(j)


  proc eqIdent*(a, b: string): bool = cmpIgnoreStyle(a, b) == 0
    ## Check if two idents are identical.

  proc eqIdent*(node: NimNode; s: string): bool {.compileTime.} =
    ## Check if node is some identifier node (``nnkIdent``, ``nnkSym``, etc.)
    ## is the same as ``s``. Note that this is the preferred way to check! Most
    ## other ways like ``node.ident`` are much more error-prone, unfortunately.
    case node.kind
    of nnkSym, nnkIdent:
      result = eqIdent(node.strVal, s)
    of nnkOpenSymChoice, nnkClosedSymChoice:
      result = eqIdent($node[0], s)
    else:
      result = false

proc hasArgOfName*(params: NimNode; name: string): bool {.compiletime.}=
  ## Search nnkFormalParams for an argument.
  expectKind(params, nnkFormalParams)
  for i in 1 ..< params.len:
    template node: untyped = params[i]
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

proc boolVal*(n: NimNode): bool {.compileTime, noSideEffect.} =
  if n.kind == nnkIntLit: n.intVal != 0
  else: n == bindSym"true" # hacky solution for now

macro expandMacros*(body: typed): typed =
  ## Expands one level of macro - useful for debugging.
  ## Can be used to inspect what happens when a macro call is expanded,
  ## without altering its result.
  ##
  ## For instance,
  ##
  ## .. code-block:: nim
  ##   import future, macros
  ##
  ##   let
  ##     x = 10
  ##     y = 20
  ##   expandMacros:
  ##     dump(x + y)
  ##
  ## will actually dump `x + y`, but at the same time will print at
  ## compile time the expansion of the ``dump`` macro, which in this
  ## case is ``debugEcho ["x + y", " = ", x + y]``.
  echo body.toStrLit
  result = body

proc customPragmaNode(n: NimNode): NimNode =
  expectKind(n, {nnkSym, nnkDotExpr, nnkBracketExpr, nnkTypeOfExpr, nnkCheckedFieldExpr})
  let
    typ = n.getTypeInst()

  if typ.kind == nnkBracketExpr and typ.len > 1 and typ[1].kind == nnkProcTy:
    return typ[1][1]
  elif typ.typeKind == ntyTypeDesc:
    let impl = typ[1].getImpl()
    if impl[0].kind == nnkPragmaExpr:
      return impl[0][1]
    else:
      return impl[0] # handle types which don't have macro at all

  if n.kind == nnkSym: # either an variable or a proc
    let impl = n.getImpl()
    if impl.kind in RoutineNodes:
      return impl.pragma
    elif impl.kind == nnkIdentDefs and impl[0].kind == nnkPragmaExpr:
      return impl[0][1]
    else:
      let timpl = typ.getImpl()
      if timpl.len>0 and timpl[0].len>1:
        return timpl[0][1]
      else:
        return timpl

  if n.kind in {nnkDotExpr, nnkCheckedFieldExpr}:
    let name = $(if n.kind == nnkCheckedFieldExpr: n[0][1] else: n[1])
    let typInst = getTypeInst(if n.kind == nnkCheckedFieldExpr or n[0].kind == nnkHiddenDeref: n[0][0] else: n[0])
    var typDef = getImpl(if typInst.kind == nnkVarTy: typInst[0] else: typInst)
    while typDef != nil:
      typDef.expectKind(nnkTypeDef)
      let typ = typDef[2]
      typ.expectKind({nnkRefTy, nnkPtrTy, nnkObjectTy})
      let isRef = typ.kind in {nnkRefTy, nnkPtrTy}
      if isRef and typ[0].kind in {nnkSym, nnkBracketExpr}: # defines ref type for another object(e.g. X = ref X)
        typDef = getImpl(typ[0])
      else: # object definition, maybe an object directly defined as a ref type
        let
          obj = (if isRef: typ[0] else: typ)
        var identDefsStack = newSeq[NimNode](obj[2].len)
        for i in 0..<identDefsStack.len: identDefsStack[i] = obj[2][i]
        while identDefsStack.len > 0:
          var identDefs = identDefsStack.pop()
          if identDefs.kind == nnkRecCase:
            identDefsStack.add(identDefs[0])
            for i in 1..<identDefs.len:
              let varNode = identDefs[i]
              # if it is and empty branch, skip
              if varNode[0].kind == nnkNilLit: continue
              if varNode[1].kind == nnkIdentDefs:
                identDefsStack.add(varNode[1])
              else: # nnkRecList
                for j in 0 ..< varNode[1].len:
                  identDefsStack.add(varNode[1][j])

          else:
            for i in 0 .. identDefs.len - 3:
              let varNode = identDefs[i]
              if varNode.kind == nnkPragmaExpr:
                var varName = varNode[0]
                if varName.kind == nnkPostfix:
                  # This is a public field. We are skipping the postfix *
                  varName = varName[1]
                if eqIdent($varName, name):
                  return varNode[1]

        if obj[1].kind == nnkOfInherit: # explore the parent object
          typDef = getImpl(obj[1][0])
        else:
          typDef = nil

macro hasCustomPragma*(n: typed, cp: typed{nkSym}): untyped =
  ## Expands to `true` if expression `n` which is expected to be `nnkDotExpr`
  ## (if checking a field), a proc or a type has custom pragma `cp`.
  ##
  ## See also `getCustomPragmaVal`.
  ##
  ## .. code-block:: nim
  ##   template myAttr() {.pragma.}
  ##   type
  ##     MyObj = object
  ##       myField {.myAttr.}: int
  ##
  ##   proc myProc() {.myAttr.} = discard
  ##
  ##   var o: MyObj
  ##   assert(o.myField.hasCustomPragma(myAttr))
  ##   assert(myProc.hasCustomPragma(myAttr))
  let pragmaNode = customPragmaNode(n)
  for p in pragmaNode:
    if (p.kind == nnkSym and p == cp) or
        (p.kind in nnkPragmaCallKinds and p.len > 0 and p[0].kind == nnkSym and p[0] == cp):
      return newLit(true)
  return newLit(false)

macro getCustomPragmaVal*(n: typed, cp: typed{nkSym}): untyped =
  ## Expands to value of custom pragma `cp` of expression `n` which is expected
  ## to be `nnkDotExpr`, a proc or a type.
  ##
  ## See also `hasCustomPragma`
  ##
  ## .. code-block:: nim
  ##   template serializationKey(key: string) {.pragma.}
  ##   type
  ##     MyObj {.serializationKey: "mo".} = object
  ##       myField {.serializationKey: "mf".}: int
  ##   var o: MyObj
  ##   assert(o.myField.getCustomPragmaVal(serializationKey) == "mf")
  ##   assert(o.getCustomPragmaVal(serializationKey) == "mo")
  ##   assert(MyObj.getCustomPragmaVal(serializationKey) == "mo")
  let pragmaNode = customPragmaNode(n)
  for p in pragmaNode:
    if p.kind in nnkPragmaCallKinds and p.len > 0 and p[0].kind == nnkSym and p[0] == cp:
      if p.len == 2:
        result = p[1]
      else:
        let def = p[0].getImpl[3]
        result = newTree(nnkPar)
        for i in 1 ..< def.len:
          let key = def[i][0]
          let val = p[i]
          result.add newTree(nnkExprColonExpr, key, val)
      break
  if result.kind == nnkEmpty:
    error(n.repr & " doesn't have a pragma named " & cp.repr()) # returning an empty node results in most cases in a cryptic error,


when not defined(booting):
  template emit*(e: static[string]): untyped {.deprecated.} =
    ## accepts a single string argument and treats it as nim code
    ## that should be inserted verbatim in the program
    ## Example:
    ##
    ## .. code-block:: nim
    ##   emit("echo " & '"' & "hello world".toUpper & '"')
    ##
    ## Deprecated since version 0.15 since it's so rarely useful.
    macro payload: untyped {.gensym.} =
      result = parseStmt(e)
    payload()

macro unpackVarargs*(callee: untyped; args: varargs[untyped]): untyped =
  result = newCall(callee)
  for i in 0 ..< args.len:
    result.add args[i]

proc getProjectPath*(): string = discard
  ## Returns the path to the currently compiling project, not to
  ## be confused with ``system.currentSourcePath`` which returns
  ## the path of the current module.
