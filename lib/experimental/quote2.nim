import macros
export macros

template expectNimNode(arg: untyped): NimNode = arg
  ## This template is here just to insert the type check. When the
  ## typecheck to ``NimNode`` fails the user will get a nice error
  ## message.

proc substitudeComments(symbols, values, n: NimNode): NimNode =
  ## substitudes all nodes of kind nnkCommentStmt to parameter
  ## symbols. Consumes the argument `n`.
  if n.kind == nnkCommentStmt:
    values.add newCall(bindSym"newCommentStmtNode", newLit(n.strVal))
    # Gensym doesn't work for parameters. These identifiers won't
    # clash unless an argument is constructed to clash here.
    symbols.add ident("comment" & $values.len & "_XObBdOnh6meCuJK2smZV")
    return symbols[^1]
  for i in 0 ..< n.len:
    n[i] = substitudeComments(symbols, values, n[i])
  return n

macro quoteAst*(args: varargs[untyped]): untyped =
  ## New Quasi-quoting operator.  Accepts an expression or a block and
  ## returns the AST that represents it.  Within the quoted AST, you
  ## are able to inject NimNode expressions from the surrounding scope
  ## if you explicitly inject their symbol.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##
  ##   macro check(ex: untyped) =
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
  ##     result = quoteAst(ex,info,expString):
  ##       if not ex:
  ##         echo info & ": Check failed: " & expString

  # This is a workaround for #10430 where comments are removed in
  # template expansions. This workaround lifts all comments
  # statements to be arguments of the temporary template.

  let extraCommentSymbols = newNimNode(nnkBracket)
  let extraCommentGenExpr = newNimNode(nnkBracket)
  let body = substitudeComments(
    extraCommentSymbols, extraCommentGenExpr, args[^1]
  )

  let formalParams = nnkFormalParams.newTree(ident"untyped")
  for i in 0 ..< args.len-1:
    formalParams.add nnkIdentDefs.newTree(
      args[i], ident"untyped", newEmptyNode()
    )
  for sym in extraCommentSymbols:
    formalParams.add nnkIdentDefs.newTree(
      sym, ident"untyped", newEmptyNode()
    )

  let templateSym = genSym(nskTemplate)
  let templateDef = nnkTemplateDef.newTree(
    templateSym,
    newEmptyNode(),
    newEmptyNode(),
    formalParams,
    nnkPragma.newTree(ident"dirty"),
    newEmptyNode(),
    nnkStmtList.newTree(
      args[^1]
    )
  )

  let templateCall = newCall(templateSym)
  for i in 0 ..< args.len-1:
    templateCall.add newCall(bindSym"expectNimNode", args[i])
  for expr in extraCommentGenExpr:
    templateCall.add expr
  let getAstCall = newCall(bindSym"getAst", templateCall)
  result = newStmtList(templateDef, getAstCall)

macro addQuoteAst*(dst: NimNode, args: varargs[untyped]): void =
  let call = newCall(bindSym"quoteAst")
  for arg in args:
    call.add arg
  result = newCall(bindSym"add", dst, call)
