import std/macros

type GenAstOpt* = enum
  kDirtyTemplate,
    # When set, uses a dirty template in implementation of `genAst`. This
    # is occasionally useful as workaround for issues such as #8220, see
    # `strformat limitations <strformat.html#limitations>`_ for details.
    # Default is unset, to avoid hijacking of uncaptured local symbols by
    # symbols in caller scope.
  kNoNewLit,
    # don't call call newLit automatically in `genAst` capture parameters

macro genAstOpt*(options: static set[GenAstOpt], args: varargs[untyped]): untyped =
  ## Accepts a list of captured variables `a=b` or `a` and a block and returns the
  ## AST that represents it. Local `{.inject.}` symbols (e.g. procs) are captured
  ## unless `kDirtyTemplate in options`.
  runnableExamples:
    macro fun(a: bool, b: static bool): untyped =
      let c = false # doesn't override parameter `c`
      var d = 11 # var => gensym'd
      proc localFun(): auto = 12 # proc => inject'd
      genAst(a, b, c = true):
        # echo d # not captured => gives `var not init`
        (a, b, c, localFun())
    assert fun(true, false) == (true, false, true, 12)

  let params = newTree(nnkFormalParams, newEmptyNode())
  let pragmas =
    if kDirtyTemplate in options:
      nnkPragma.newTree(ident"dirty")
    else:
      newEmptyNode()

  template newLitMaybe(a): untyped =
    when (a is type) or (typeof(a) is (proc | iterator | func | NimNode)):
      a # `proc` actually also covers template, macro
    else: newLit(a)

  # using `_` as workaround, see https://github.com/nim-lang/Nim/issues/2465#issuecomment-511076669
  let name = genSym(nskTemplate, "_fun")
  let call = newCall(name)
  for a in args[0..^2]:
    var varName: NimNode
    var varVal: NimNode
    case a.kind
    of nnkExprEqExpr:
      varName = a[0]
      varVal = a[1]
    of nnkIdent:
      varName = a
      varVal = a
    else: error("invalid argument kind: " & $a.kind, a)
    if kNoNewLit notin options: varVal = newCall(bindSym"newLitMaybe", varVal)

    params.add newTree(nnkIdentDefs, varName, newEmptyNode(), newEmptyNode())
    call.add varVal

  result = newStmtList()
  result.add nnkTemplateDef.newTree(
      name,
      newEmptyNode(),
      newEmptyNode(),
      params,
      pragmas,
      newEmptyNode(),
      args[^1])
  result.add newCall(bindSym"getAst", call)

template genAst*(args: varargs[untyped]): untyped =
  ## convenience wrapper around `genAstOpt`
  genAstOpt({}, args)
