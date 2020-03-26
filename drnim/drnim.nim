#
#
#            Doctor Nim
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

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
    mapping: Table[int, Z3_ast]

proc notImplemented(msg: string) {.noinline.} =
  raise newException(CannotMapToZ3Error, "cannot map to Z3: " & msg)

proc typeToZ3(c: DrCon; t: PType): Z3_sort =
  template ctx: untyped = c.z3
  case t.skipTypes(abstractInst).kind
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

proc nodeToZ3(c: var DrCon; n: PNode; vars: var seq[PNode]): Z3_ast =
  template ctx: untyped = c.z3
  case n.kind
  of nkSym:
    result = c.mapping.getOrDefault(n.sym.id)
    if pointer(result) == nil:
      let name = Z3_mk_string_symbol(ctx, n.sym.name.s)
      result = Z3_mk_const(ctx, name, typeToZ3(c, n.sym.typ))
      c.mapping[n.sym.id] = result
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
    template rec(n): untyped = nodeToZ3(c, n, vars)

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
        let sym = n[1].sym
        result = c.mapping.getOrDefault(-sym.id)
        if pointer(result) == nil:
          let name = Z3_mk_string_symbol(ctx, sym.name.s & ".len")
          result = Z3_mk_const(ctx, name, Z3_mk_int_sort(ctx))
          c.mapping[-sym.id] = result
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
    else:
      notImplemented(renderTree(n))
  else:
    notImplemented(renderTree(n))

proc addRangeInfo(c: var DrCon, n: PNode, res: var seq[Z3_ast]) =
  let cmpOp =
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
  else:
    # we know it's a 'len(x)' expression and we seek to teach
    # Z3 that the result is >= 0 and <= high(int).
    doAssert n.kind in nkCallKinds
    doAssert n[0].kind == nkSym
    doAssert n.len == 2

    lowBound = newIntNode(nkInt64Lit, 0)
    highBound = newIntNode(nkInt64Lit, lastOrd(nil, n.typ))

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

proc proofEngine(graph: ModuleGraph; assumptions: seq[PNode]; toProve: PNode): (bool, string) =
  var c: DrCon
  c.graph = graph
  c.mapping = initTable[int, Z3_ast]()
  let cfg = Z3_mk_config()
  Z3_set_param_value(cfg, "model", "true");
  let ctx = Z3_mk_context(cfg)
  c.z3 = ctx
  Z3_del_config(cfg)
  Z3_set_error_handler(ctx, on_err)

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
      let za = nodeToZ3(c, assumption, collectedVars)
      #Z3_solver_assert ctx, solver, za
      lhs.add za

    let z3toProve = nodeToZ3(c, toProve, collectedVars)
    for v in collectedVars:
      addRangeInfo(c, v, lhs)

    # to make Z3 produce nice counterexamples, we try to prove the
    # negation of our conjecture and see if it's Z3_L_FALSE
    let fa = Z3_mk_not(ctx, Z3_mk_implies(ctx, conj(ctx, lhs), z3toProve))

    #Z3_mk_not(ctx, forall(ctx, collectedVars, conj(ctx, lhs), z3toProve))

    #echo "toProve: ", Z3_ast_to_string(ctx, fa)
    Z3_solver_assert ctx, solver, fa

    let z3res = Z3_solver_check(ctx, solver)
    result[0] = z3res == Z3_L_FALSE
    if not result[0]:
      result[1] = strip $Z3_model_to_string(ctx, Z3_solver_get_model(ctx, solver))
    else:
      result[1] = ""
  except ValueError:
    result[0] = false
    result[1] = getCurrentExceptionMsg()
  finally:
    Z3_del_context(ctx)

proc mainCommand(graph: ModuleGraph) =
  let conf = graph.config
  conf.lastCmdTime = epochTime()

  graph.proofEngine = proofEngine

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

#[
Thoughts on subtyping rules for 'proc' types:

  proc q(y: int) {.requires: y > 0.}  # q is 'weaker' than T
  # 'requires' must be weaker (or equal)
  # 'ensures'  must be stronger (or equal)

  # a 'is weaker than' b iff  b -> a
  # a 'is stronger than' b iff a -> b
  # --> We can use Z3 to compute whether 'var x: T = q' is valid

  type
    T = proc (y: int) {.requires: y > 5.}

  var
    x: T = q # valid?
]#

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
