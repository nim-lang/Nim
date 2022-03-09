import macros

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
    # This example shows how one could write a simplified version of `unittest.check`.
    import std/[macros, strutils]
    macro check2(cond: bool): untyped =
      assert cond.kind == nnkInfix, "$# not implemented" % $cond.kind
      result = genAst(cond, s = repr(cond), lhs = cond[1], rhs = cond[2]):
        # each local symbol we access must be explicitly captured
        if not cond:
          doAssert false, "'$#'' failed: lhs: '$#', rhs: '$#'" % [s, $lhs, $rhs]
    let a = 3
    check2 a*2 == a+3
    if false: check2 a*2 < a+1 # would error with: 'a * 2 < a + 1'' failed: lhs: '6', rhs: '4'

  runnableExamples:
    # This example goes in more details about the capture semantics.
    macro fun(a: string, b: static bool): untyped =
      let c = 'z'
      var d = 11 # implicitly {.gensym.} and needs to be captured for use in `genAst`.
      proc localFun(): auto = 12 # implicitly {.inject.}, doesn't need to be captured.
      genAst(a, b, c = true):
        # `a`, `b` are captured explicitly, `c` is a local definition masking `c = 'z'`.
        const b2 = b # macro static param `b` is forwarded here as a static param.
        # `echo d` would give: `var not init` because `d` is not captured.
        (a & a, b, c, localFun()) # localFun can be called without capture.
    assert fun("ab", false) == ("abab", false, true, 12)

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
  ## Convenience wrapper around `genAstOpt`.
  genAstOpt({}, args)
