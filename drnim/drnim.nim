#
#
#            Doctor Nim
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

#[

- Most important bug:

  while i < x.len and use(s[i]): inc i # is safe

- We need to map arrays to Z3 and test for something like 'forall(i, (i in 3..4) -> (a[i] > 3))'
- forall/exists need syntactic sugar as the manual
- We need teach DrNim what 'inc', 'dec' and 'swap' mean, for example
  'x in n..m; inc x' implies 'x in n+1..m+1'

- We need an ``old`` annotation:

proc f(x: var int; y: var int) {.ensures: x == old(x)+1 and y == old(y)+1 .} =
  inc x
  inc y

var x = 3
var y: range[N..M]
f(x, y)
{.assume: y in N+1 .. M+1.}
# --> y in N+1..M+1

proc myinc(x: var int) {.ensures: x-1 == old(x).} =
  inc x

facts(x) # x < 3
myinc x
facts(x+1)

We handle state transitions in this way:

  for every f in facts:
    replace 'x' by 'old(x)'
  facts.add ensuresClause

  # then we know: old(x) < 3; x-1 == old(x)
  # we can conclude:  x-1 < 3 but leave this task to Z3

]#

import std / [
  parseopt, strutils, os, tables, times
]

import ".." / compiler / [
  ast, types, renderer,
  commands, options, msgs,
  platform,
  idents, lineinfos, cmdlinehelper, modulegraphs, condsyms,
  pathutils, passes, passaux, sem, modules
]

import z3 / z3_api

when not defined(windows):
  # on UNIX we use static linking because UNIX's lib*.so system is broken
  # beyond repair and the neckbeards don't understand software development.
  {.passL: "dist/z3/build/libz3.a".}

const
  HelpMessage = "DrNim Version $1 [$2: $3]\n" &
      "Compiled at $4\n" &
      "Copyright (c) 2006-" & copyrightYear & " by Andreas Rumpf\n"

const
  Usage = """
drnim [options] [projectfile]

Options: Same options that the Nim compiler supports.
"""

proc getCommandLineDesc(conf: ConfigRef): string =
  result = (HelpMessage % [system.NimVersion, platform.OS[conf.target.hostOS].name,
                           CPU[conf.target.hostCPU].name, CompileDate]) &
                           Usage

proc helpOnError(conf: ConfigRef) =
  msgWriteln(conf, getCommandLineDesc(conf), {msgStdout})
  msgQuit(0)

type
  CannotMapToZ3Error = object of ValueError
  Z3Exception = object of ValueError

  DrCon = object
    z3: Z3_context
    graph: ModuleGraph
    mapping: Table[string, Z3_ast]
    canonParameterNames: bool

proc stableName(result: var string; n: PNode) =
  # we can map full Nim expressions like 'f(a, b, c)' to Z3 variables.
  # We must be carefult to select a unique, stable name for these expressions
  # based on structural equality. 'stableName' helps us with this problem.
  case n.kind
  of nkEmpty, nkNilLit, nkType: discard
  of nkIdent:
    result.add n.ident.s
  of nkSym:
    result.add n.sym.name.s
    result.add '_'
    result.addInt n.sym.id
  of nkCharLit..nkUInt64Lit:
    result.addInt n.intVal
  of nkFloatLit..nkFloat64Lit:
    result.addFloat n.floatVal
  of nkStrLit..nkTripleStrLit:
    result.add strutils.escape n.strVal
  else:
    result.add $n.kind
    result.add '('
    for i in 0..<n.len:
      if i > 0: result.add ", "
      stableName(result, n[i])
    result.add ')'

proc stableName(n: PNode): string = stableName(result, n)

proc notImplemented(msg: string) {.noinline.} =
  raise newException(CannotMapToZ3Error, "; cannot map to Z3: " & msg)

proc translateEnsures(e, x: PNode): PNode =
  if e.kind == nkSym and e.sym.kind == skResult:
    result = x
  else:
    result = shallowCopy(e)
    for i in 0 ..< safeLen(e):
      result[i] = translateEnsures(e[i], x)

proc typeToZ3(c: DrCon; t: PType): Z3_sort =
  template ctx: untyped = c.z3
  case t.skipTypes(abstractInst+{tyVar}).kind
  of tyEnum, tyInt..tyInt64:
    result = Z3_mk_int_sort(ctx)
  of tyBool:
    result = Z3_mk_bool_sort(ctx)
  of tyFloat..tyFloat128:
    result = Z3_mk_fpa_sort_double(ctx)
  of tyChar, tyUInt..tyUInt64:
    result = Z3_mk_bv_sort(ctx, 64)
    #cuint(getSize(c.graph.config, t) * 8))
  else:
    notImplemented(typeToString(t))

template binary(op, a, b): untyped =
  var arr = [a, b]
  op(ctx, cuint(2), addr(arr[0]))

proc nodeToZ3(c: var DrCon; n: PNode; vars: var seq[PNode]): Z3_ast

template quantorToZ3(fn) {.dirty.} =
  template ctx: untyped = c.z3

  var bound = newSeq[Z3_app](n.len-1)
  for i in 0..n.len-2:
    doAssert n[i].kind == nkSym
    let v = n[i].sym
    let name = Z3_mk_string_symbol(ctx, v.name.s)
    let vz3 = Z3_mk_const(ctx, name, typeToZ3(c, v.typ))
    c.mapping[stableName(n[i])] = vz3
    bound[i] = Z3_to_app(ctx, vz3)

  var dummy: seq[PNode]
  let x = nodeToZ3(c, n[^1], dummy)
  result = fn(ctx, 0, bound.len.cuint, addr(bound[0]), 0, nil, x)

proc forallToZ3(c: var DrCon; n: PNode): Z3_ast = quantorToZ3(Z3_mk_forall_const)
proc existsToZ3(c: var DrCon; n: PNode): Z3_ast = quantorToZ3(Z3_mk_exists_const)

proc paramName(n: PNode): string =
  case n.sym.kind
  of skParam: result = "arg" & $n.sym.position
  of skResult: result = "result"
  else: result = stableName(n)

proc nodeToZ3(c: var DrCon; n: PNode; vars: var seq[PNode]): Z3_ast =
  template ctx: untyped = c.z3
  template rec(n): untyped = nodeToZ3(c, n, vars)
  case n.kind
  of nkSym:
    let key = if c.canonParameterNames: paramName(n) else: stableName(n)
    result = c.mapping.getOrDefault(key)
    if pointer(result) == nil:
      let name = Z3_mk_string_symbol(ctx, n.sym.name.s)
      result = Z3_mk_const(ctx, name, typeToZ3(c, n.sym.typ))
      c.mapping[key] = result
      vars.add n
  of nkCharLit..nkUInt64Lit:
    if n.typ != nil and n.typ.skipTypes(abstractInst).kind in {tyInt..tyInt64}:
      # optimized for the common case
      result = Z3_mk_int64(ctx, clonglong(n.intval), Z3_mk_int_sort(ctx))
    elif n.typ != nil and n.typ.kind == tyBool:
      result = if n.intval != 0: Z3_mk_true(ctx) else: Z3_mk_false(ctx)
    elif n.typ != nil and isUnsigned(n.typ):
      result = Z3_mk_unsigned_int64(ctx, cast[uint64](n.intVal), typeToZ3(c, n.typ))
    else:
      let zt = if n.typ == nil: Z3_mk_int_sort(ctx) else: typeToZ3(c, n.typ)
      result = Z3_mk_numeral(ctx, $getOrdValue(n), zt)
  of nkFloatLit..nkFloat64Lit:
    result = Z3_mk_fpa_numeral_double(ctx, n.floatVal, Z3_mk_fpa_sort_double(ctx))
  of nkCallKinds:
    assert n.len > 0
    assert n[0].kind == nkSym
    let operator = n[0].sym.magic
    case operator
    of mEqI, mEqF64, mEqEnum, mEqCh, mEqB, mEqRef, mEqProc,
        mEqStr, mEqSet, mEqCString:
      result = Z3_mk_eq(ctx, rec n[1], rec n[2])
    of mLeI, mLeEnum, mLeCh, mLeB, mLePtr, mLeStr:
      result = Z3_mk_le(ctx, rec n[1], rec n[2])
    of mLtI, mLtEnum, mLtCh, mLtB, mLtPtr, mLtStr:
      result = Z3_mk_lt(ctx, rec n[1], rec n[2])
    of mLengthOpenArray, mLengthStr, mLengthArray, mLengthSeq:
      # len(x) needs the same logic as 'x' itself
      if n[1].kind == nkSym:
        let key = stableName(n)
        let sym = n[1].sym
        result = c.mapping.getOrDefault(key)
        if pointer(result) == nil:
          let name = Z3_mk_string_symbol(ctx, sym.name.s & ".len")
          result = Z3_mk_const(ctx, name, Z3_mk_int_sort(ctx))
          c.mapping[key] = result
          vars.add n
      else:
        notImplemented(renderTree(n))
    of mAddI, mSucc:
      result = binary(Z3_mk_add, rec n[1], rec n[2])
    of mSubI, mPred:
      result = binary(Z3_mk_sub, rec n[1], rec n[2])
    of mMulI:
      result = binary(Z3_mk_mul, rec n[1], rec n[2])
    of mDivI:
      result = Z3_mk_div(ctx, rec n[1], rec n[2])
    of mModI:
      result = Z3_mk_mod(ctx, rec n[1], rec n[2])
    of mMaxI:
      # max(a, b) <=> ite(a < b, b, a)
      result = Z3_mk_ite(ctx, Z3_mk_lt(ctx, rec n[1], rec n[2]),
        rec n[2], rec n[1])
    of mMinI:
      # min(a, b) <=> ite(a < b, a, b)
      result = Z3_mk_ite(ctx, Z3_mk_lt(ctx, rec n[1], rec n[2]),
        rec n[1], rec n[2])
    of mLeU:
      result = Z3_mk_bvule(ctx, rec n[1], rec n[2])
    of mLtU:
      result = Z3_mk_bvult(ctx, rec n[1], rec n[2])
    of mAnd:
      result = binary(Z3_mk_and, rec n[1], rec n[2])
    of mOr:
      result = binary(Z3_mk_or, rec n[1], rec n[2])
    of mXor:
      result = Z3_mk_xor(ctx, rec n[1], rec n[2])
    of mNot:
      result = Z3_mk_not(ctx, rec n[1])
    of mImplies:
      result = Z3_mk_implies(ctx, rec n[1], rec n[2])
    of mIff:
      result = Z3_mk_iff(ctx, rec n[1], rec n[2])
    of mForall:
      result = forallToZ3(c, n)
    of mExists:
      result = existsToZ3(c, n)
    of mLeF64:
      result = Z3_mk_fpa_leq(ctx, rec n[1], rec n[2])
    of mLtF64:
      result = Z3_mk_fpa_lt(ctx, rec n[1], rec n[2])
    of mAddF64:
      result = Z3_mk_fpa_add(ctx, Z3_mk_fpa_round_nearest_ties_to_even(ctx), rec n[1], rec n[2])
    of mSubF64:
      result = Z3_mk_fpa_sub(ctx, Z3_mk_fpa_round_nearest_ties_to_even(ctx), rec n[1], rec n[2])
    of mMulF64:
      result = Z3_mk_fpa_mul(ctx, Z3_mk_fpa_round_nearest_ties_to_even(ctx), rec n[1], rec n[2])
    of mDivF64:
      result = Z3_mk_fpa_div(ctx, Z3_mk_fpa_round_nearest_ties_to_even(ctx), rec n[1], rec n[2])
    of mShrI:
      # XXX handle conversions from int to uint here somehow
      result = Z3_mk_bvlshr(ctx, rec n[1], rec n[2])
    of mAshrI:
      result = Z3_mk_bvashr(ctx, rec n[1], rec n[2])
    of mShlI:
      result = Z3_mk_bvshl(ctx, rec n[1], rec n[2])
    of mBitandI:
      result = Z3_mk_bvand(ctx, rec n[1], rec n[2])
    of mBitorI:
      result = Z3_mk_bvor(ctx, rec n[1], rec n[2])
    of mBitxorI:
      result = Z3_mk_bvxor(ctx, rec n[1], rec n[2])
    of mOrd, mChr:
      result = rec n[1]
    of mOld:
      let key = (if c.canonParameterNames: paramName(n[1]) else: stableName(n[1])) & ".old"
      result = c.mapping.getOrDefault(key)
      if pointer(result) == nil:
        let name = Z3_mk_string_symbol(ctx, $n)
        result = Z3_mk_const(ctx, name, typeToZ3(c, n.typ))
        c.mapping[key] = result
        # XXX change the logic in `addRangeInfo` for this
        #vars.add n

    else:
      # sempass2 adds some 'fact' like 'x = f(a, b)' (see addAsgnFact)
      # 'f(a, b)' can have an .ensures annotation and we need to make use
      # of this information.
      # we need to map 'f(a, b)' to a Z3 variable of this name
      let op = n[0].typ
      if op != nil and op.n != nil and op.n.len > 0 and op.n[0].kind == nkEffectList and
          ensuresEffects < op.n[0].len:
        let ensures = op.n[0][ensuresEffects]
        if ensures != nil and ensures.kind != nkEmpty:
          let key = stableName(n)
          result = c.mapping.getOrDefault(key)
          if pointer(result) == nil:
            let name = Z3_mk_string_symbol(ctx, $n)
            result = Z3_mk_const(ctx, name, typeToZ3(c, n.typ))
            c.mapping[key] = result
            vars.add n

      if pointer(result) == nil:
        notImplemented(renderTree(n))
  of nkStmtListExpr, nkPar:
    var isTrivial = true
    for i in 0..n.len-2:
      isTrivial = isTrivial and n[i].kind in {nkEmpty, nkCommentStmt}
    if isTrivial:
      result = nodeToZ3(c, n[^1], vars)
    else:
      notImplemented(renderTree(n))
  of nkHiddenDeref:
    result = rec n[0]
  else:
    notImplemented(renderTree(n))

proc addRangeInfo(c: var DrCon, n: PNode, res: var seq[Z3_ast]) =
  var cmpOp = mLeI
  if n.typ != nil:
    cmpOp =
      case n.typ.skipTypes(abstractInst).kind
      of tyFloat..tyFloat128: mLeF64
      of tyChar, tyUInt..tyUInt64: mLeU
      else: mLeI

  var lowBound, highBound: PNode
  if n.kind == nkSym:
    let v = n.sym
    let t = v.typ.skipTypes(abstractInst - {tyRange})

    case t.kind
    of tyRange:
      lowBound = t.n[0]
      highBound = t.n[1]
    of tyFloat..tyFloat128:
      # no range information for non-range'd floats
      return
    of tyUInt..tyUInt64, tyChar:
      lowBound = newIntNode(nkUInt64Lit, firstOrd(nil, v.typ))
      lowBound.typ = v.typ
      highBound = newIntNode(nkUInt64Lit, lastOrd(nil, v.typ))
      highBound.typ = v.typ
    of tyInt..tyInt64, tyEnum:
      lowBound = newIntNode(nkInt64Lit, firstOrd(nil, v.typ))
      highBound = newIntNode(nkInt64Lit, lastOrd(nil, v.typ))
    else:
      # no range information available:
      return
  elif n.kind in nkCallKinds and n.len == 2 and n[0].kind == nkSym and
      n[0].sym.magic in {mLengthOpenArray, mLengthStr, mLengthArray, mLengthSeq}:
    # we know it's a 'len(x)' expression and we seek to teach
    # Z3 that the result is >= 0 and <= high(int).
    doAssert n.kind in nkCallKinds
    doAssert n[0].kind == nkSym
    doAssert n.len == 2

    lowBound = newIntNode(nkInt64Lit, 0)
    if n.typ != nil:
      highBound = newIntNode(nkInt64Lit, lastOrd(nil, n.typ))
    else:
      highBound = newIntNode(nkInt64Lit, high(int64))
  else:
    let op = n[0].typ
    if op != nil and op.n != nil and op.n.len > 0 and op.n[0].kind == nkEffectList and
        ensuresEffects < op.n[0].len:
      let ensures = op.n[0][ensuresEffects]
      if ensures != nil and ensures.kind != nkEmpty:
        var dummy: seq[PNode]
        res.add nodeToZ3(c, translateEnsures(ensures, n), dummy)
    return

  let x = newTree(nkInfix, newSymNode createMagic(c.graph, "<=", cmpOp), lowBound, n)
  let y = newTree(nkInfix, newSymNode createMagic(c.graph, "<=", cmpOp), n, highBound)

  var dummy: seq[PNode]
  res.add nodeToZ3(c, x, dummy)
  res.add nodeToZ3(c, y, dummy)

proc on_err(ctx: Z3_context, e: Z3_error_code) {.nimcall.} =
  #writeStackTrace()
  let msg = $Z3_get_error_msg(ctx, e)
  raise newException(Z3Exception, msg)

proc forall(ctx: Z3_context; vars: seq[Z3_ast]; assumption, body: Z3_ast): Z3_ast =
  let x = Z3_mk_implies(ctx, assumption, body)
  if vars.len > 0:
    var bound: seq[Z3_app]
    for v in vars: bound.add Z3_to_app(ctx, v)
    result = Z3_mk_forall_const(ctx, 0, bound.len.cuint, addr(bound[0]), 0, nil, x)
  else:
    result = x

proc conj(ctx: Z3_context; conds: seq[Z3_ast]): Z3_ast =
  if conds.len > 0:
    result = Z3_mk_and(ctx, cuint(conds.len), unsafeAddr conds[0])
  else:
    result = Z3_mk_true(ctx)

proc proofEngineAux(c: var DrCon; assumptions: seq[PNode]; toProve: PNode): (bool, string) =
  c.mapping = initTable[string, Z3_ast]()
  let cfg = Z3_mk_config()
  Z3_set_param_value(cfg, "model", "true");
  let ctx = Z3_mk_context(cfg)
  c.z3 = ctx
  Z3_del_config(cfg)
  Z3_set_error_handler(ctx, on_err)

  when false:
    Z3_set_param_value(cfg, "timeout", "1000")

  try:

    #[
    For example, let's have these facts:

      i < 10
      i > 0

    Question:

      i + 3 < 13

    What we need to produce:

    forall(i, (i < 10) & (i > 0) -> (i + 3 < 13))

    ]#

    var collectedVars: seq[PNode]

    let solver = Z3_mk_solver(ctx)
    var lhs: seq[Z3_ast]
    for assumption in assumptions:
      if assumption != nil:
        try:
          let za = nodeToZ3(c, assumption, collectedVars)
          #Z3_solver_assert ctx, solver, za
          lhs.add za
        except CannotMapToZ3Error:
          discard "ignore a fact we cannot map to Z3"

    let z3toProve = nodeToZ3(c, toProve, collectedVars)
    for v in collectedVars:
      addRangeInfo(c, v, lhs)

    # to make Z3 produce nice counterexamples, we try to prove the
    # negation of our conjecture and see if it's Z3_L_FALSE
    let fa = Z3_mk_not(ctx, Z3_mk_implies(ctx, conj(ctx, lhs), z3toProve))

    #Z3_mk_not(ctx, forall(ctx, collectedVars, conj(ctx, lhs), z3toProve))

    #echo "toProve: ", Z3_ast_to_string(ctx, fa), " ", c.graph.config $ toProve.info
    Z3_solver_assert ctx, solver, fa

    let z3res = Z3_solver_check(ctx, solver)
    result[0] = z3res == Z3_L_FALSE
    result[1] = ""
    if not result[0]:
      let counterex = strip($Z3_model_to_string(ctx, Z3_solver_get_model(ctx, solver)))
      if counterex.len > 0:
        result[1].add "; counter example: " & counterex
  except ValueError:
    result[0] = false
    result[1] = getCurrentExceptionMsg()
  finally:
    Z3_del_context(ctx)

proc proofEngine(graph: ModuleGraph; assumptions: seq[PNode]; toProve: PNode): (bool, string) =
  var c: DrCon
  c.graph = graph
  result = proofEngineAux(c, assumptions, toProve)

proc translateReq(r, call: PNode): PNode =
  if r.kind == nkSym and r.sym.kind == skParam:
    if r.sym.position+1 < call.len:
      result = call[r.sym.position+1]
    else:
      notImplemented("no argument given for formal parameter: " & r.sym.name.s)
  else:
    result = shallowCopy(r)
    for i in 0 ..< safeLen(r):
      result[i] = translateReq(r[i], call)

proc requirementsCheck(graph: ModuleGraph; assumptions: seq[PNode];
                      call, requirement: PNode): (bool, string) {.nimcall.} =
  try:
    let r = translateReq(requirement, call)
    result = proofEngine(graph, assumptions, r)
  except ValueError:
    result[0] = false
    result[1] = getCurrentExceptionMsg()

proc compatibleProps(graph: ModuleGraph; formal, actual: PType): bool {.nimcall.} =
  #[
  Thoughts on subtyping rules for 'proc' types:

    proc a(y: int) {.requires: y > 0.}  # a is 'weaker' than F
    # 'requires' must be weaker (or equal)
    # 'ensures'  must be stronger (or equal)

    # a 'is weaker than' b iff  b -> a
    # a 'is stronger than' b iff a -> b
    # --> We can use Z3 to compute whether 'var x: T = q' is valid

    type
      F = proc (y: int) {.requires: y > 5.}

    var
      x: F = a # valid?
  ]#
  proc isEmpty(n: PNode): bool {.inline.} = n == nil or n.safeLen == 0

  result = true
  if formal.n != nil and formal.n.len > 0 and formal.n[0].kind == nkEffectList and
      ensuresEffects < formal.n[0].len:

    let frequires = formal.n[0][requiresEffects]
    let fensures = formal.n[0][ensuresEffects]

    if actual.n != nil and actual.n.len > 0 and actual.n[0].kind == nkEffectList and
        ensuresEffects < actual.n[0].len:
      let arequires = actual.n[0][requiresEffects]
      let aensures = actual.n[0][ensuresEffects]

      var c: DrCon
      c.graph = graph
      c.canonParameterNames = true
      if not frequires.isEmpty:
        result = not arequires.isEmpty and proofEngineAux(c, @[frequires], arequires)[0]

      if result:
        if not fensures.isEmpty:
          result = not aensures.isEmpty and proofEngineAux(c, @[aensures], fensures)[0]
    else:
      # formal has requirements but 'actual' has none, so make it
      # incompatible. XXX What if the requirement only mentions that
      # we already know from the type system?
      result = frequires.isEmpty and fensures.isEmpty

proc mainCommand(graph: ModuleGraph) =
  let conf = graph.config
  conf.lastCmdTime = epochTime()

  graph.proofEngine = proofEngine
  graph.requirementsCheck = requirementsCheck
  graph.compatibleProps = compatibleProps

  graph.config.errorMax = high(int)  # do not stop after first error
  defineSymbol(graph.config.symbols, "nimcheck")
  defineSymbol(graph.config.symbols, "nimDrNim")

  registerPass graph, verbosePass
  registerPass graph, semPass
  compileProject(graph)
  if conf.errorCounter == 0:
    let mem =
      when declared(system.getMaxMem): formatSize(getMaxMem()) & " peakmem"
      else: formatSize(getTotalMem()) & " totmem"
    let loc = $conf.linesCompiled
    let build = if isDefined(conf, "danger"): "Dangerous Release"
                elif isDefined(conf, "release"): "Release"
                else: "Debug"
    let sec = formatFloat(epochTime() - conf.lastCmdTime, ffDecimal, 3)
    let project = if optListFullPaths in conf.globalOptions: $conf.projectFull else: $conf.projectName
    var output = $conf.absOutFile
    if optListFullPaths notin conf.globalOptions: output = output.AbsoluteFile.extractFilename
    rawMessage(conf, hintSuccessX, [
      "loc", loc,
      "sec", sec,
      "mem", mem,
      "build", build,
      "project", project,
      "output", output,
      ])

proc prependCurDir(f: AbsoluteFile): AbsoluteFile =
  when defined(unix):
    if os.isAbsolute(f.string): result = f
    else: result = AbsoluteFile("./" & f.string)
  else:
    result = f

proc addCmdPrefix(result: var string, kind: CmdLineKind) =
  # consider moving this to std/parseopt
  case kind
  of cmdLongOption: result.add "--"
  of cmdShortOption: result.add "-"
  of cmdArgument, cmdEnd: discard

proc processCmdLine(pass: TCmdLinePass, cmd: string; config: ConfigRef) =
  var p = parseopt.initOptParser(cmd)
  var argsCount = 1

  config.commandLine.setLen 0
  config.command = "check"
  config.cmd = cmdCheck

  while true:
    parseopt.next(p)
    case p.kind
    of cmdEnd: break
    of cmdLongOption, cmdShortOption:
      config.commandLine.add " "
      config.commandLine.addCmdPrefix p.kind
      config.commandLine.add p.key.quoteShell # quoteShell to be future proof
      if p.val.len > 0:
        config.commandLine.add ':'
        config.commandLine.add p.val.quoteShell

      if p.key == " ":
        p.key = "-"
        if processArgument(pass, p, argsCount, config): break
      else:
        processSwitch(pass, p, config)
    of cmdArgument:
      config.commandLine.add " "
      config.commandLine.add p.key.quoteShell
      if processArgument(pass, p, argsCount, config): break
  if pass == passCmd2:
    if {optRun, optWasNimscript} * config.globalOptions == {} and
        config.arguments.len > 0 and config.command.normalize notin ["run", "e"]:
      rawMessage(config, errGenerated, errArgsNeedRunOption)

proc handleCmdLine(cache: IdentCache; conf: ConfigRef) =
  let self = NimProg(
    supportsStdinFile: true,
    processCmdLine: processCmdLine,
    mainCommand: mainCommand
  )
  self.initDefinesProg(conf, "drnim")
  if paramCount() == 0:
    helpOnError(conf)
    return

  self.processCmdLineAndProjectPath(conf)
  if not self.loadConfigsAndRunMainCommand(cache, conf): return
  if conf.hasHint(hintGCStats): echo(GC_getStatistics())

when compileOption("gc", "v2") or compileOption("gc", "refc"):
  # the new correct mark&sweep collector is too slow :-/
  GC_disableMarkAndSweep()

when not defined(selftest):
  let conf = newConfigRef()
  handleCmdLine(newIdentCache(), conf)
  when declared(GC_setMaxPause):
    echo GC_getStatistics()
  msgQuit(int8(conf.errorCounter > 0))
