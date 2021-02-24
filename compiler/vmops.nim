#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Unfortunately this cannot be a module yet:
#import vmdeps, vm
from std/math import sqrt, ln, log10, log2, exp, round, arccos, arcsin,
  arctan, arctan2, cos, cosh, hypot, sinh, sin, tan, tanh, pow, trunc,
  floor, ceil, `mod`, cbrt, arcsinh, arccosh, arctanh, erf, erfc, gamma,
  lgamma

when declared(math.copySign):
  from std/math import copySign

when declared(math.signbit):
  from std/math import signbit

from std/os import getEnv, existsEnv, dirExists, fileExists, putEnv, walkDir,
                   getAppFilename, raiseOSError, osLastError

from std/md5 import getMD5
from std/times import cpuTime
from std/hashes import hash
from std/osproc import nil
from std/sysrand import urandom

from sighashes import symBodyDigest

# There are some useful procs in vmconv.
import vmconv

template mathop(op) {.dirty.} =
  registerCallback(c, "stdlib.math." & astToStr(op), `op Wrapper`)

template osop(op) {.dirty.} =
  registerCallback(c, "stdlib.os." & astToStr(op), `op Wrapper`)

template timesop(op) {.dirty.} =
  registerCallback(c, "stdlib.times." & astToStr(op), `op Wrapper`)

template systemop(op) {.dirty.} =
  registerCallback(c, "stdlib.system." & astToStr(op), `op Wrapper`)

template ioop(op) {.dirty.} =
  registerCallback(c, "stdlib.io." & astToStr(op), `op Wrapper`)

template macrosop(op) {.dirty.} =
  registerCallback(c, "stdlib.macros." & astToStr(op), `op Wrapper`)

template md5op(op) {.dirty.} =
  registerCallback(c, "stdlib.md5." & astToStr(op), `op Wrapper`)

template wrap1f_math(op) {.dirty.} =
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    doAssert a.numArgs == 1
    setResult(a, op(getFloat(a, 0)))
  mathop op

template wrap2f_math(op) {.dirty.} =
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    setResult(a, op(getFloat(a, 0), getFloat(a, 1)))
  mathop op

template wrap0(op, modop) {.dirty.} =
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    setResult(a, op())
  modop op

template wrap1s(op, modop) {.dirty.} =
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    setResult(a, op(getString(a, 0)))
  modop op

template wrap2s(op, modop) {.dirty.} =
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    setResult(a, op(getString(a, 0), getString(a, 1)))
  modop op

template wrap2si(op, modop) {.dirty.} =
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    setResult(a, op(getString(a, 0), getInt(a, 1)))
  modop op

template wrap1svoid(op, modop) {.dirty.} =
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    op(getString(a, 0))
  modop op

template wrap2svoid(op, modop) {.dirty.} =
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    op(getString(a, 0), getString(a, 1))
  modop op

template wrapDangerous(op, modop) {.dirty.} =
  if vmopsDanger notin c.config.features and (defined(nimsuggest) or c.config.cmd == cmdCheck):
    proc `op Wrapper`(a: VmArgs) {.nimcall.} =
      discard
    modop op
  else:
    proc `op Wrapper`(a: VmArgs) {.nimcall.} =
      op(getString(a, 0), getString(a, 1))
    modop op

proc getCurrentExceptionMsgWrapper(a: VmArgs) {.nimcall.} =
  setResult(a, if a.currentException.isNil: ""
               else: a.currentException[3].skipColon.strVal)

proc getCurrentExceptionWrapper(a: VmArgs) {.nimcall.} =
  setResult(a, a.currentException)

proc staticWalkDirImpl(path: string, relative: bool): PNode =
  result = newNode(nkBracket)
  for k, f in walkDir(path, relative):
    result.add toLit((k, f))

when defined(nimHasInvariant):
  from std / compilesettings import SingleValueSetting, MultipleValueSetting

  proc querySettingImpl(conf: ConfigRef, switch: BiggestInt): string =
    case SingleValueSetting(switch)
    of arguments: result = conf.arguments
    of outFile: result = conf.outFile.string
    of outDir: result = conf.outDir.string
    of nimcacheDir: result = conf.getNimcacheDir().string
    of projectName: result = conf.projectName
    of projectPath: result = conf.projectPath.string
    of projectFull: result = conf.projectFull.string
    of command: result = conf.command
    of commandLine: result = conf.commandLine
    of linkOptions: result = conf.linkOptions
    of compileOptions: result = conf.compileOptions
    of ccompilerPath: result = conf.cCompilerPath
    of backend: result = $conf.backend
    of libPath: result = conf.libpath.string

  proc querySettingSeqImpl(conf: ConfigRef, switch: BiggestInt): seq[string] =
    template copySeq(field: untyped): untyped =
      for i in field: result.add i.string

    case MultipleValueSetting(switch)
    of nimblePaths: copySeq(conf.nimblePaths)
    of searchPaths: copySeq(conf.searchPaths)
    of lazyPaths: copySeq(conf.lazyPaths)
    of commandArgs: result = conf.commandArgs
    of cincludes: copySeq(conf.cIncludes)
    of clibs: copySeq(conf.cLibs)

proc registerAdditionalOps*(c: PCtx) =
  proc gorgeExWrapper(a: VmArgs) =
    let ret = opGorge(getString(a, 0), getString(a, 1), getString(a, 2),
                         a.currentLineInfo, c.config)
    setResult a, ret.toLit

  proc getProjectPathWrapper(a: VmArgs) =
    setResult a, c.config.projectPath.string

  wrap1f_math(sqrt)
  wrap1f_math(cbrt)
  wrap1f_math(ln)
  wrap1f_math(log10)
  wrap1f_math(log2)
  wrap1f_math(exp)
  wrap1f_math(arccos)
  wrap1f_math(arcsin)
  wrap1f_math(arctan)
  wrap1f_math(arcsinh)
  wrap1f_math(arccosh)
  wrap1f_math(arctanh)
  wrap2f_math(arctan2)
  wrap1f_math(cos)
  wrap1f_math(cosh)
  wrap2f_math(hypot)
  wrap1f_math(sinh)
  wrap1f_math(sin)
  wrap1f_math(tan)
  wrap1f_math(tanh)
  wrap2f_math(pow)
  wrap1f_math(trunc)
  wrap1f_math(floor)
  wrap1f_math(ceil)
  wrap1f_math(erf)
  wrap1f_math(erfc)
  wrap1f_math(gamma)
  wrap1f_math(lgamma)

  when declared(copySign):
    wrap2f_math(copySign)

  when declared(signbit):
    wrap1f_math(signbit)

  registerCallback c, "stdlib.math.round", proc (a: VmArgs) {.nimcall.} =
    let n = a.numArgs
    case n
    of 1: setResult(a, round(getFloat(a, 0)))
    of 2: setResult(a, round(getFloat(a, 0), getInt(a, 1).int))
    else: doAssert false, $n

  wrap1s(getMD5, md5op)

  proc `mod Wrapper`(a: VmArgs) {.nimcall.} =
    setResult(a, `mod`(getFloat(a, 0), getFloat(a, 1)))
  registerCallback(c, "stdlib.math.mod", `mod Wrapper`)

  when defined(nimcore):
    wrap2s(getEnv, osop)
    wrap1s(existsEnv, osop)
    wrap2svoid(putEnv, osop)
    wrap1s(dirExists, osop)
    wrap1s(fileExists, osop)
    wrapDangerous(writeFile, ioop)
    wrap1s(readFile, ioop)
    wrap2si(readLines, ioop)
    systemop getCurrentExceptionMsg
    systemop getCurrentException
    registerCallback c, "stdlib.*.staticWalkDir", proc (a: VmArgs) {.nimcall.} =
      setResult(a, staticWalkDirImpl(getString(a, 0), getBool(a, 1)))
    when defined(nimHasInvariant):
      registerCallback c, "stdlib.compilesettings.querySetting", proc (a: VmArgs) =
        setResult(a, querySettingImpl(c.config, getInt(a, 0)))
      registerCallback c, "stdlib.compilesettings.querySettingSeq", proc (a: VmArgs) =
        setResult(a, querySettingSeqImpl(c.config, getInt(a, 0)))

    if defined(nimsuggest) or c.config.cmd == cmdCheck:
      discard "don't run staticExec for 'nim suggest'"
    else:
      systemop gorgeEx
  macrosop getProjectPath

  registerCallback c, "stdlib.os.getCurrentCompilerExe", proc (a: VmArgs) {.nimcall.} =
    setResult(a, getAppFilename())

  registerCallback c, "stdlib.macros.symBodyHash", proc (a: VmArgs) =
    let n = getNode(a, 0)
    if n.kind != nkSym:
      stackTrace(c, PStackFrame(prc: c.prc.sym, comesFrom: 0, next: nil), c.exceptionInstr,
                  "symBodyHash() requires a symbol. '" & $n & "' is of kind '" & $n.kind & "'", n.info)
    setResult(a, $symBodyDigest(c.graph, n.sym))

  registerCallback c, "stdlib.macros.isExported", proc(a: VmArgs) =
    let n = getNode(a, 0)
    if n.kind != nkSym:
      stackTrace(c, PStackFrame(prc: c.prc.sym, comesFrom: 0, next: nil), c.exceptionInstr,
                  "isExported() requires a symbol. '" & $n & "' is of kind '" & $n.kind & "'", n.info)
    setResult(a, sfExported in n.sym.flags)

  proc hashVmImpl(a: VmArgs) =
    var res = hashes.hash(a.getString(0), a.getInt(1).int, a.getInt(2).int)
    if c.config.backend == backendJs:
      # emulate JS's terrible integers:
      res = cast[int32](res)
    setResult(a, res)

  registerCallback c, "stdlib.hashes.hashVmImpl", hashVmImpl

  proc hashVmImplByte(a: VmArgs) =
    # nkBracket[...]
    let sPos = a.getInt(1).int
    let ePos = a.getInt(2).int
    let arr = a.getNode(0)
    var bytes = newSeq[byte](arr.len)
    for i in 0..<arr.len:
      bytes[i] = byte(arr[i].intVal and 0xff)

    var res = hashes.hash(bytes, sPos, ePos)
    if c.config.backend == backendJs:
      # emulate JS's terrible integers:
      res = cast[int32](res)
    setResult(a, res)

  registerCallback c, "stdlib.hashes.hashVmImplByte", hashVmImplByte
  registerCallback c, "stdlib.hashes.hashVmImplChar", hashVmImplByte

  if optBenchmarkVM in c.config.globalOptions or vmopsDanger in c.config.features:
    wrap0(cpuTime, timesop)
  else:
    proc cpuTime(): float = 5.391245e-44  # Randomly chosen
    wrap0(cpuTime, timesop)

  if vmopsDanger in c.config.features:
    ## useful procs but these should be opt-in because they may impact
    ## reproducible builds and users need to understand that this runs at CT.
    ## Note that `staticExec` can already do equal amount of damage so it's more
    ## of a semantic issue than a security issue.
    registerCallback c, "stdlib.os.getCurrentDir", proc (a: VmArgs) {.nimcall.} =
      setResult(a, os.getCurrentDir())
    registerCallback c, "stdlib.osproc.execCmdEx", proc (a: VmArgs) {.nimcall.} =
      let options = getNode(a, 1).fromLit(set[osproc.ProcessOption])
      a.setResult osproc.execCmdEx(getString(a, 0), options).toLit
    registerCallback c, "stdlib.times.getTime", proc (a: VmArgs) {.nimcall.} =
      setResult(a, times.getTime().toLit)

  proc getEffectList(c: PCtx; a: VmArgs; effectIndex: int) =
    let fn = getNode(a, 0)
    if fn.typ != nil and fn.typ.n != nil and fn.typ.n[0].len >= effectListLen and
        fn.typ.n[0][effectIndex] != nil:
      var list = newNodeI(nkBracket, fn.info)
      for e in fn.typ.n[0][effectIndex]:
        list.add opMapTypeInstToAst(c.cache, e.typ.skipTypes({tyRef}), e.info, c.idgen)
      setResult(a, list)

  registerCallback c, "stdlib.effecttraits.getRaisesListImpl", proc (a: VmArgs) =
    getEffectList(c, a, exceptionEffects)
  registerCallback c, "stdlib.effecttraits.getTagsListImpl", proc (a: VmArgs) =
    getEffectList(c, a, tagEffects)

  registerCallback c, "stdlib.effecttraits.isGcSafeImpl", proc (a: VmArgs) =
    let fn = getNode(a, 0)
    setResult(a, fn.typ != nil and tfGcSafe in fn.typ.flags)

  registerCallback c, "stdlib.effecttraits.hasNoSideEffectsImpl", proc (a: VmArgs) =
    let fn = getNode(a, 0)
    setResult(a, (fn.typ != nil and tfNoSideEffect in fn.typ.flags) or
                 (fn.kind == nkSym and fn.sym.kind == skFunc))

  if vmopsDanger in c.config.features:
    proc urandomImpl(a: VmArgs) =
      doAssert a.numArgs == 1
      let kind = a.slots[a.rb+1].kind
      case kind
      of rkInt:
        setResult(a, urandom(a.getInt(0)).toLit)
      of rkNode, rkNodeAddr:
        let n =
          if kind == rkNode:
            a.getNode(0)
          else:
            a.getNodeAddr(0)

        let length = n.len

        ## TODO refactor using vmconv.fromLit
        var res = newSeq[uint8](length)
        for i in 0 ..< length:
          res[i] = byte(n[i].intVal)

        let isSuccess = urandom(res)

        for i in 0 ..< length:
          n[i].intVal = BiggestInt(res[i])

        setResult(a, isSuccess)
      else:
        doAssert false, $kind

    registerCallback c, "stdlib.sysrand.urandom", urandomImpl
