#
#
#            Doctor Nim
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when false:
  # ICON linking
  when defined(gcc) and defined(windows):
    when defined(x86):
      {.link: "../icons/nim.res".}
    else:
      {.link: "../icons/nim_icon.o".}

  when defined(amd64) and defined(windows) and defined(vcc):
    {.link: "../icons/nim-amd64-windows-vcc.res".}
  when defined(i386) and defined(windows) and defined(vcc):
    {.link: "../icons/nim-i386-windows-vcc.res".}

import std / [
  parseopt, strutils, os, tables
]

import ".." / compiler / [
  ast, astalgo, types,
  commands, options, msgs,
  extccomp,
  idents, lineinfos, cmdlinehelper, modulegraphs, condsyms,
  pathutils, passes, passaux, sem, modules
]

import z3 / z3_api

type
  CannotMapToZ3Error = object of ValueError
  Z3Exception = object of ValueError

proc typeToZ3(c: Z3_context; t: PType): Z3_sort =
  case t.skipTypes(abstractInst).kind
  of tyInt:
    result = Z3_mk_int_sort(c)
  of tyBool:
    result = Z3_mk_bool_sort(c)
  else:
    assert false, "not implemented " & typeToString(t)

template binary(op, a, b): untyped =
  var arr = [a, b]
  op(ctx, cuint(2), addr(arr[0]))

proc nodeToZ3(ctx: Z3_context; n: PNode; mapping: var Table[int, Z3_ast];
              collectedVars: var seq[Z3_ast]): Z3_ast =
  case n.kind
  of nkSym:
    result = mapping.getOrDefault(n.sym.id)
    if pointer(result) == nil:
      let name = Z3_mk_string_symbol(ctx, n.sym.name.s)
      result = Z3_mk_const(ctx, name, typeToZ3(ctx, n.sym.typ))
      mapping[n.sym.id] = result
      collectedVars.add result
  of nkIntLit:
    result = Z3_mk_int64(ctx, clonglong(n.intval), Z3_mk_int_sort(ctx))
  of nkCallKinds:
    template rec(n): untyped = nodeToZ3(ctx, n, mapping, collectedVars)

    assert n.len > 0
    assert n[0].kind == nkSym
    let operator = n[0].sym.magic
    case operator
    of mEqI, mEqF64, mEqEnum, mEqCh, mEqB, mEqRef, mEqProc,
        mEqStr, mEqSet, mEqCString:
      result = Z3_mk_eq(ctx, rec n[1], rec n[2])
    of mLeI, mLeF64, mLeU, mLeEnum, mLeCh, mLeB, mLePtr, mLeStr:
      result = Z3_mk_le(ctx, rec n[1], rec n[2])
    of mLtI, mLtF64, mLtU, mLtEnum, mLtCh, mLtB, mLtPtr, mLtStr:
      result = Z3_mk_lt(ctx, rec n[1], rec n[2])
    of mLengthOpenArray, mLengthStr, mLengthArray, mLengthSeq:
      # len(x) needs the same logic as 'x' itself
      if n[1].kind == nkSym:
        let sym = n[1].sym
        result = mapping.getOrDefault(-sym.id)
        if pointer(result) == nil:
          let name = Z3_mk_string_symbol(ctx, sym.name.s & ".len")
          result = Z3_mk_const(ctx, name, Z3_mk_int_sort(ctx))
          mapping[-sym.id] = result
          collectedVars.add result
      else:
        assert false, "length of not-symbol?"
    of mInSet:
      assert false, "Not implemented 'in' operator for sets"
    of mAddI, mAddF64, mSucc:
      result = binary(Z3_mk_add, rec n[1], rec n[2])
    of mSubI, mSubF64, mPred:
      result = binary(Z3_mk_sub, rec n[1], rec n[2])
    of mMulI, mMulF64:
      result = binary(Z3_mk_mul, rec n[1], rec n[2])
    of mDivI, mDivF64:
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
    else:
      assert false, "not implemented"
  else:
    assert false, "not implemented"

proc on_err(ctx: Z3_context, e: Z3_error_code) {.nimcall.} =
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
  var mapping = initTable[int, Z3_ast]()
  let cfg = Z3_mk_config()
  Z3_set_param_value(cfg, "model", "true");
  let ctx = Z3_mk_context(cfg)
  #let fpa_rm {.inject used.} = Z3_mk_fpa_round_nearest_ties_to_even(ctx)
  Z3_del_config(cfg)
  Z3_set_error_handler(ctx, on_err)

  #[
  For example, let's have these facts:

    i < 10
    i > 0

  Question:

    i + 3 < 13

  What we need to produce:

  forall(i, (i < 10) & (i > 0) -> (i + 3 < 13))

  ]#

  var collectedVars: seq[Z3_ast]

  let solver = Z3_mk_solver(ctx)
  var lhs: seq[Z3_ast]
  for assumption in assumptions:
    let za = nodeToZ3(ctx, assumption, mapping, collectedVars)
    #Z3_solver_assert ctx, solver, za
    lhs.add za

  let z3toProve = nodeToZ3(ctx, toProve, mapping, collectedVars)

  let fa = forall(ctx, collectedVars, conj(ctx, lhs), z3toProve)
  #echo "toProve: ", Z3_ast_to_string(ctx, fa)
  Z3_solver_assert ctx, solver, fa

  let z3res = Z3_solver_check(ctx, solver)
  result[0] = z3res == Z3_L_TRUE
  when false:
    if not result[0]:
      result[1] = $Z3_model_to_string(ctx, Z3_solver_get_model(ctx, solver))
  result[1] = ""
  Z3_del_context(ctx)

proc mainCommand(graph: ModuleGraph) =
  graph.proofEngine = proofEngine

  graph.config.errorMax = high(int)  # do not stop after first error
  defineSymbol(graph.config.symbols, "nimcheck")

  registerPass graph, verbosePass
  registerPass graph, semPass
  compileProject(graph)


proc prependCurDir(f: AbsoluteFile): AbsoluteFile =
  when defined(unix):
    if os.isAbsolute(f.string): result = f
    else: result = AbsoluteFile("./" & f.string)
  else:
    result = f

proc addCmdPrefix*(result: var string, kind: CmdLineKind) =
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
  self.initDefinesProg(conf, "nim_compiler")
  if paramCount() == 0:
    writeCommandLineUsage(conf)
    return

  self.processCmdLineAndProjectPath(conf)
  if not self.loadConfigsAndRunMainCommand(cache, conf): return
  if conf.hasHint(hintGCStats): echo(GC_getStatistics())

when compileOption("gc", "v2") or compileOption("gc", "refc"):
  # the new correct mark&sweet collector is too slow :-/
  GC_disableMarkAndSweep()

when not defined(selftest):
  let conf = newConfigRef()
  handleCmdLine(newIdentCache(), conf)
  when declared(GC_setMaxPause):
    echo GC_getStatistics()
  msgQuit(int8(conf.errorCounter > 0))
