# this is a copy paste implementation of github.com/krux02/ast_pattern_matching
# Please provide bugfixes upstream first before adding them here.

import macros, strutils, tables

export macros

when isMainModule:
  template debug(args: varargs[untyped]): untyped =
    echo args
else:
  template debug(args: varargs[untyped]): untyped =
    discard

const
  nnkIntLiterals*   = nnkCharLit..nnkUInt64Lit
  nnkStringLiterals* = nnkStrLit..nnkTripleStrLit
  nnkFloatLiterals* = nnkFloatLit..nnkFloat64Lit

proc newLit[T: enum](arg: T): NimNode =
  newIdentNode($arg)

proc newLit[T](arg: set[T]): NimNode =
  ## does not work for the empty sets
  result = nnkCurly.newTree
  for x in arg:
    result.add newLit(x)

type SomeFloat = float | float32 | float64

proc len[T](arg: set[T]): int = card(arg)

type
  MatchingErrorKind* = enum
    NoError
    WrongKindLength
    WrongKindValue
    WrongIdent
    WrongCustomCondition

  MatchingError = object
    node*: NimNode
    expectedKind*: set[NimNodeKind]
    case kind*: MatchingErrorKind
    of NoError:
      discard
    of WrongKindLength:
      expectedLength*: int
    of WrongKindValue:
      expectedValue*: NimNode
    of WrongIdent, WrongCustomCondition:
      strVal*: string

proc `$`*(arg: MatchingError): string =
  let n = arg.node
  case arg.kind
  of NoError:
    "no error"
  of WrongKindLength:
    let k = arg.expectedKind
    let l = arg.expectedLength
    var msg = "expected "
    if k.len == 0:
      msg.add "any node"
    elif k.len == 1:
      for el in k:  # only one element but there is no index op for sets
        msg.add $el
    else:
      msg.add "a node in" & $k

    if l >= 0:
      msg.add " with " & $l & " child(ren)"
    msg.add ", but got " & $n.kind
    if l >= 0:
      msg.add " with " & $n.len & " child(ren)"
    msg
  of WrongKindValue:
    let k = $arg.expectedKind
    let v = arg.expectedValue.repr
    var msg = "expected " & k & " with value " & v & " but got " & n.lispRepr
    if n.kind in {nnkOpenSymChoice, nnkClosedSymChoice}:
      msg = msg & " (a sym-choice does not have a strVal member, maybe you should match with `ident`)"
    msg
  of WrongIdent:
    let prefix = "expected ident `" & arg.strVal & "` but got "
    if n.kind in {nnkIdent, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice}:
      prefix & "`" & n.strVal & "`"
    else:
      prefix & $n.kind & " with " & $n.len & " child(ren)"
  of WrongCustomCondition:
    "custom condition check failed: " & arg.strVal


proc failWithMatchingError*(arg: MatchingError): void {.compileTime, noReturn.} =
  error($arg, arg.node)

proc expectValue(arg: NimNode; value: SomeInteger): void {.compileTime.} =
  arg.expectKind nnkLiterals
  if arg.intVal != int(value):
    error("expected value " & $value & " but got " & arg.repr, arg)

proc expectValue(arg: NimNode; value: SomeFloat): void {.compileTime.} =
  arg.expectKind nnkLiterals
  if arg.floatVal != float(value):
    error("expected value " & $value & " but got " & arg.repr, arg)

proc expectValue(arg: NimNode; value: string): void {.compileTime.} =
  arg.expectKind nnkLiterals
  if arg.strVal != value:
    error("expected value " & value & " but got " & arg.repr, arg)

proc expectValue[T](arg: NimNode; value: pointer): void {.compileTime.} =
  arg.expectKind nnkLiterals
  if value != nil:
    error("Expect Value for pointers works only on `nil` when the argument is a pointer.")
  arg.expectKind nnkNilLit

proc expectIdent(arg: NimNode; strVal: string): void {.compileTime.} =
  if not arg.eqIdent(strVal):
    error("Expect ident `" & strVal & "` but got " & arg.repr)

proc matchLengthKind*(arg: NimNode; kind: set[NimNodeKind]; length: int): MatchingError {.compileTime.} =
  let kindFail   = not(kind.card == 0 or arg.kind in kind)
  let lengthFail = not(length < 0 or length == arg.len)
  if kindFail or lengthFail:
    result.node = arg
    result.kind = WrongKindLength
    result.expectedLength = length
    result.expectedKind   = kind


proc matchLengthKind*(arg: NimNode; kind: NimNodeKind; length: int): MatchingError {.compileTime.} =
  matchLengthKind(arg, {kind}, length)

proc matchValue(arg: NimNode; kind: set[NimNodeKind]; value: SomeInteger): MatchingError {.compileTime.} =
  template kindFail: bool  = not(kind.card == 0 or arg.kind in kind)
  template valueFail: bool = arg.intVal != int(value)
  if kindFail or valueFail:
    result.node = arg
    result.kind = WrongKindValue
    result.expectedKind  = kind
    result.expectedValue = newLit(value)

proc matchValue(arg: NimNode; kind: NimNodeKind; value: SomeInteger): MatchingError {.compileTime.} =
  matchValue(arg, {kind}, value)

proc matchValue(arg: NimNode; kind: set[NimNodeKind]; value: SomeFloat): MatchingError {.compileTime.} =
  let kindFail   = not(kind.card == 0 or arg.kind in kind)
  let valueFail  = arg.floatVal != float(value)
  if kindFail or valueFail:
    result.node = arg
    result.kind = WrongKindValue
    result.expectedKind  = kind
    result.expectedValue = newLit(value)

proc matchValue(arg: NimNode; kind: NimNodeKind; value: SomeFloat): MatchingError {.compileTime.} =
  matchValue(arg, {kind}, value)

const nnkStrValKinds = {nnkStrLit, nnkRStrLit, nnkTripleStrLit, nnkIdent, nnkSym}

proc matchValue(arg: NimNode; kind: set[NimNodeKind]; value: string): MatchingError {.compileTime.} =
  # if kind * nnkStringLiterals TODO do something that ensures that here is only checked for string literals
  let kindFail   = not(kind.card == 0 or arg.kind in kind)
  let valueFail  =
    if kind.card == 0:
      false
    else:
      arg.kind notin (kind * nnkStrValKinds) or arg.strVal != value
  if kindFail or valueFail:
    result.node = arg
    result.kind = WrongKindValue
    result.expectedKind  = kind
    result.expectedValue = newLit(value)

proc matchValue(arg: NimNode; kind: NimNodeKind; value: string): MatchingError {.compileTime.} =
  matchValue(arg, {kind}, value)

proc matchValue[T](arg: NimNode; value: pointer): MatchingError {.compileTime.} =
  if value != nil:
    error("Expect Value for pointers works only on `nil` when the argument is a pointer.")
  arg.matchLengthKind(nnkNilLit, -1)

proc matchIdent*(arg:NimNode; value: string): MatchingError =
  if not arg.eqIdent(value):
    result.node = arg
    result.kind = Wrongident
    result.strVal = value

proc checkCustomExpr*(arg: NimNode; cond: bool, exprstr: string): MatchingError =
  if not cond:
    result.node = arg
    result.kind = WrongCustomCondition
    result.strVal = exprstr

static:
  var literals: array[19, NimNode]
  var i = 0
  for litKind in nnkLiterals:
    literals[i] = ident($litKind)
    i += 1

  var nameToKind = newTable[string, NimNodeKind]()
  for kind in NimNodeKind:
    nameToKind[ ($kind)[3..^1] ] = kind

  let identifierKinds = newLit({nnkSym, nnkIdent, nnkOpenSymChoice, nnkClosedSymChoice})

proc generateMatchingCode(astSym: NimNode, pattern: NimNode, depth: int, blockLabel, errorSym, localsArraySym: NimNode; dest: NimNode): int =
  ## return the number of indices used in the array for local variables.

  var currentLocalIndex = 0

  proc nodeVisiting(astSym: NimNode, pattern: NimNode, depth: int): void =
    let ind = "  ".repeat(depth) # indentation

    proc genMatchLogic(matchProc, argSym1, argSym2: NimNode): void =
      dest.add quote do:
        `errorSym` = `astSym`.`matchProc`(`argSym1`, `argSym2`)
        if `errorSym`.kind != NoError:
          break `blockLabel`

    proc genIdentMatchLogic(identValueLit: NimNode): void =
      dest.add quote do:
        `errorSym` = `astSym`.matchIdent(`identValueLit`)
        if `errorSym`.kind != NoError:
          break `blockLabel`

    proc genCustomMatchLogic(conditionExpr: NimNode): void =
      let exprStr = newLit(conditionExpr.repr)
      dest.add quote do:
        `errorSym` = `astSym`.checkCustomExpr(`conditionExpr`, `exprStr`)
        if `errorSym`.kind != NoError:
          break `blockLabel`

    # proc handleKindMatching(kindExpr: NimNode): void =
    #   if kindExpr.eqIdent("_"):
    #     # this is the wildcand that matches any kind
    #     return
    #   else:
    #     genMatchLogic(bindSym"matchKind", kindExpr)

    # generate recursively a matching expression
    if pattern.kind == nnkCall:
      pattern.expectMinLen(1)

      debug ind, pattern[0].repr, "("

      let kindSet = if pattern[0].eqIdent("_"): nnkCurly.newTree else: pattern[0]
      # handleKindMatching(pattern[0])

      if pattern.len == 2 and pattern[1].kind == nnkExprEqExpr:
        if pattern[1][1].kind in nnkStringLiterals:
          pattern[1][0].expectIdent("strVal")
        elif pattern[1][1].kind in nnkIntLiterals:
          pattern[1][0].expectIdent("intVal")
        elif pattern[1][1].kind in nnkFloatLiterals:
          pattern[1][0].expectIdent("floatVal")

        genMatchLogic(bindSym"matchValue", kindSet, pattern[1][1])

      else:
        let lengthLit = newLit(pattern.len - 1)
        genMatchLogic(bindSym"matchLengthKind", kindSet, lengthLit)

        for i in 1 ..< pattern.len:
          let childSym = nnkBracketExpr.newTree(localsArraySym, newLit(currentLocalIndex))
          currentLocalIndex += 1
          let indexLit = newLit(i - 1)
          dest.add quote do:
            `childSym` = `astSym`[`indexLit`]
          nodeVisiting(childSym, pattern[i], depth + 1)
      debug ind, ")"
    elif pattern.kind == nnkCallStrLit and pattern[0].eqIdent("ident"):
      genIdentMatchLogic(pattern[1])

    elif pattern.kind == nnkPar and pattern.len == 1:
      nodeVisiting(astSym, pattern[0], depth)
    elif pattern.kind == nnkPrefix:
      error("prefix patterns not implemented", pattern)
    elif pattern.kind == nnkAccQuoted:
      debug ind, pattern.repr
      let matchedExpr = pattern[0]
      matchedExpr.expectKind nnkIdent
      dest.add quote do:
        let `matchedExpr` = `astSym`

    elif pattern.kind == nnkInfix and pattern[0].eqIdent("@"):
      pattern[1].expectKind nnkAccQuoted

      let matchedExpr = pattern[1][0]
      matchedExpr.expectKind nnkIdent
      dest.add quote do:
        let `matchedExpr` = `astSym`

      debug ind, pattern[1].repr, " = "
      nodeVisiting(matchedExpr, pattern[2], depth + 1)

    elif pattern.kind == nnkInfix and pattern[0].eqIdent("|="):
      nodeVisiting(astSym, pattern[1], depth + 1)
      genCustomMatchLogic(pattern[2])

    elif pattern.kind in nnkCallKinds:
      error("only boring call syntax allowed, this is " & $pattern.kind & ".", pattern)
    elif pattern.kind in nnkLiterals:
      genMatchLogic(bindSym"matchValue", nnkCurly.newTree, pattern)
    elif not pattern.eqIdent("_"):
      # When it is not one of the other branches, it is simply treated
      # as an expression for the node kind, without checking child
      # nodes.
      debug ind, pattern.repr
      genMatchLogic(bindSym"matchLengthKind", pattern, newLit(-1))

  nodeVisiting(astSym, pattern, depth)

  return currentLocalIndex

macro matchAst*(astExpr: NimNode; args: varargs[untyped]): untyped =
  let astSym = genSym(nskLet, "ast")
  let beginBranches = if args[0].kind == nnkIdent: 1 else: 0
  let endBranches   = if args[^1].kind == nnkElse: args.len - 1 else: args.len
  for i in beginBranches ..< endBranches:
    args[i].expectKind nnkOfBranch

  let outerErrorSym: NimNode =
    if beginBranches == 1:
      args[0].expectKind nnkIdent
      args[0]
    else:
      nil

  let elseBranch: NimNode =
    if endBranches == args.len - 1:
      args[^1].expectKind(nnkElse)
      args[^1][0]
    else:
      nil

  let outerBlockLabel = genSym(nskLabel, "matchingSection")
  let outerStmtList = newStmtList()
  let errorSymbols = nnkBracket.newTree

  ## the vm only allows 255 local variables. This sucks a lot and I
  ## have to work around it.  So instead of creating a lot of local
  ## variables, I just create one array of local variables. This is
  ## just annoying.
  let localsArraySym = genSym(nskVar, "locals")
  var localsArrayLen: int = 0

  for i in beginBranches ..< endBranches:
    let ofBranch = args[i]

    ofBranch.expectKind(nnkOfBranch)
    ofBranch.expectLen(2)
    let pattern = ofBranch[0]
    let code = ofBranch[1]
    code.expectKind nnkStmtList
    let stmtList = newStmtList()
    let blockLabel = genSym(nskLabel, "matchingBranch")
    let errorSym = genSym(nskVar, "branchError")

    errorSymbols.add errorSym
    let numLocalsUsed = generateMatchingCode(astSym, pattern, 0, blockLabel, errorSym, localsArraySym, stmtList)
    localsArrayLen = max(localsArrayLen, numLocalsUsed)
    stmtList.add code
    # maybe there is a better mechanism disable errors for statement after return
    if code[^1].kind != nnkReturnStmt:
      stmtList.add nnkBreakStmt.newTree(outerBlockLabel)

    outerStmtList.add quote do:
      var `errorSym`: MatchingError
      block `blockLabel`:
        `stmtList`

  if elseBranch != nil:
    if outerErrorSym != nil:
      outerStmtList.add quote do:
        let `outerErrorSym` = @`errorSymbols`
        `elseBranch`
    else:
      outerStmtList.add elseBranch

  else:
    if errorSymbols.len == 1:
      # there is only one of branch and no else branch
      # the error message can be very precise here.
      let errorSym = errorSymbols[0]
      outerStmtList.add quote do:
        failWithMatchingError(`errorSym`)
    else:

      var patterns: string = ""
      for i in beginBranches ..< endBranches:
        let ofBranch = args[i]
        let pattern = ofBranch[0]
        patterns.add pattern.repr
        patterns.add "\n"

      let patternsLit = newLit(patterns)
      outerStmtList.add quote do:
        error("Ast pattern mismatch: got " & `astSym`.lispRepr & "\nbut expected one of:\n" & `patternsLit`, `astSym`)

  let lengthLit = newLit(localsArrayLen)
  result = quote do:
    block `outerBlockLabel`:
      let `astSym` = `astExpr`
      var `localsArraySym`: array[`lengthLit`, NimNode]
      `outerStmtList`

  debug result.repr

proc recursiveNodeVisiting*(arg: NimNode, callback: proc(arg: NimNode): bool) =
  ## if `callback` returns true, visitor continues to visit the
  ## children of `arg` otherwise it stops.
  if callback(arg):
    for child in arg:
      recursiveNodeVisiting(child, callback)

macro matchAstRecursive*(ast: NimNode; args: varargs[untyped]): untyped =
  # Does not recurse further on matched nodes.
  if args[^1].kind == nnkElse:
    error("Recursive matching with an else branch is pointless.", args[^1])

  let visitor = genSym(nskProc, "visitor")
  let visitorArg = genSym(nskParam, "arg")

  let visitorStmtList = newStmtList()

  let matchingSection = genSym(nskLabel, "matchingSection")

  let localsArraySym = genSym(nskVar, "locals")
  let branchError = genSym(nskVar, "branchError")
  var localsArrayLen = 0

  for ofBranch in args:
    ofBranch.expectKind(nnkOfBranch)
    ofBranch.expectLen(2)
    let pattern = ofBranch[0]
    let code = ofBranch[1]
    code.expectkind(nnkStmtList)

    let stmtList = newStmtList()
    let matchingBranch = genSym(nskLabel, "matchingBranch")

    let numLocalsUsed = generateMatchingCode(visitorArg, pattern, 0, matchingBranch, branchError, localsArraySym, stmtList)
    localsArrayLen = max(localsArrayLen, numLocalsUsed)

    stmtList.add code
    stmtList.add nnkBreakStmt.newTree(matchingSection)


    visitorStmtList.add quote do:
      `branchError`.kind = NoError
      block `matchingBranch`:
        `stmtList`

  let resultIdent = ident"result"

  let visitingProc = bindSym"recursiveNodeVisiting"
  let lengthLit = newLit(localsArrayLen)

  result = quote do:
    proc `visitor`(`visitorArg`: NimNode): bool =
      block `matchingSection`:
        var `localsArraySym`: array[`lengthLit`, NimNode]
        var `branchError`: MatchingError
        `visitorStmtList`
        `resultIdent` = true

    `visitingProc`(`ast`, `visitor`)

  debug result.repr

################################################################################
################################# Example Code #################################
################################################################################

when isMainModule:
  static:
    let mykinds = {nnkIdent, nnkCall}

  macro foo(arg: untyped): untyped =
    matchAst(arg, matchError):
    of nnkStmtList(nnkIdent, nnkIdent, nnkIdent):
      echo(88*88+33*33)
    of nnkStmtList(
      _(
        nnkIdentDefs(
          ident"a",
          nnkEmpty, nnkIntLit(intVal = 123)
        )
      ),
      _,
      nnkForStmt(
        nnkIdent(strVal = "i"),
        nnkInfix,
        `mysym` @ nnkStmtList
      )
    ):
      echo "The AST did match!!!"
      echo "The matched sub tree is the following:"
      echo mysym.lispRepr
    #else:
    #  echo "sadly the AST did not match :("
    #  echo arg.treeRepr
    #  failWithMatchingError(matchError[1])

  foo:
    let a = 123
    let b = 342
    for i in a ..< b:
      echo "Hallo", i

  static:

    var ast = quote do:
      type
        A[T: static[int]] = object

    ast = ast[0]
    ast.matchAst(err):  # this is a sub ast for this a findAst or something like that is useful
    of nnkTypeDef(_, nnkGenericParams( nnkIdentDefs( nnkIdent(strVal = "T"), `staticTy`, nnkEmpty )), _):
      echo "`", staticTy.repr, "` used to be of nnkStaticTy, now it is ", staticTy.kind, " with ", staticTy[0].repr
    ast = quote do:
      if cond1: expr1 elif cond2: expr2 else: expr3

    ast.matchAst:
    of {nnkIfExpr, nnkIfStmt}(
      {nnkElifExpr, nnkElifBranch}(`cond1`, `expr1`),
      {nnkElifExpr, nnkElifBranch}(`cond2`, `expr2`),
      {nnkElseExpr, nnkElse}(`expr3`)
    ):
      echo "ok"

    let ast2 = nnkStmtList.newTree( newLit(1) )

    ast2.matchAst:
    of nnkIntLit( 1 ):
      echo "fail"
    of nnkStmtList( 1 ):
      echo "ok"

    ast = bindSym"[]"
    ast.matchAst(errors):
    of nnkClosedSymChoice(strVal = "[]"):
      echo "fail, this is the wrong syntax, a sym choice does not have a `strVal` member."
    of ident"[]":
      echo "ok"

    const myConst = 123
    ast = newLit(123)

    ast.matchAst:
    of _(intVal = myConst):
      echo "ok"

    macro testRecCase(ast: untyped): untyped =
      ast.matchAstRecursive:
      of nnkIdentDefs(`a`,`b`,`c`):
        echo "got ident defs a: ", a.repr, " b: ", b.repr, " c: ", c.repr
      of ident"m":
        echo "got the ident m"

    testRecCase:
      type Obj[T] {.inheritable.} = object
        name: string
        case isFat: bool
        of true:
          m: array[100_000, T]
        of false:
          m: array[10, T]


    macro testIfCondition(ast: untyped): untyped =
      let literals = nnkBracket.newTree
      ast.matchAstRecursive:
      of `intLit` @ nnkIntLit |= intLit.intVal > 5:
        literals.add intLit

      let literals2 = quote do:
        [6,7,8,9]

      doAssert literals2 == literals

    testIfCondition([1,6,2,7,3,8,4,9,5,0,"123"])
