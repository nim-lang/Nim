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
from math import sqrt, ln, log10, log2, exp, round, arccos, arcsin,
  arctan, arctan2, cos, cosh, hypot, sinh, sin, tan, tanh, pow, trunc,
  floor, ceil, `mod`

from os import getEnv, existsEnv, dirExists, fileExists, putEnv, walkDir, getAppFilename
from md5 import getMD5
from sighashes import symBodyDigest
from times import cpuTime

from hashes import hash

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
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    if defined(nimsuggest) or c.config.cmd == cmdCheck:
      discard
    else:
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
    result.add newTree(nkTupleConstr, newIntNode(nkIntLit, k.ord),
                              newStrNode(nkStrLit, f))

proc registerAdditionalOps*(c: PCtx) =
  proc gorgeExWrapper(a: VmArgs) =
    let (s, e) = opGorge(getString(a, 0), getString(a, 1), getString(a, 2),
                         a.currentLineInfo, c.config)
    setResult a, newTree(nkTupleConstr, newStrNode(nkStrLit, s), newIntNode(nkIntLit, e))

  proc getProjectPathWrapper(a: VmArgs) =
    setResult a, c.config.projectPath.string

  wrap1f_math(sqrt)
  wrap1f_math(ln)
  wrap1f_math(log10)
  wrap1f_math(log2)
  wrap1f_math(exp)
  wrap1f_math(round)
  wrap1f_math(arccos)
  wrap1f_math(arcsin)
  wrap1f_math(arctan)
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
    wrap2si(staticReadLines, ioop)
    systemop getCurrentExceptionMsg
    systemop getCurrentException
    registerCallback c, "stdlib.*.staticWalkDir", proc (a: VmArgs) {.nimcall.} =
      setResult(a, staticWalkDirImpl(getString(a, 0), getBool(a, 1)))

    if defined(nimsuggest) or c.config.cmd == cmdCheck:
      discard "don't run staticExec for 'nim suggest'"
    else:
      systemop gorgeEx
  macrosop getProjectPath

  registerCallback c, "stdlib.os.getCurrentCompilerExe", proc (a: VmArgs) {.nimcall.} =
    setResult(a, getAppFilename())

  registerCallback c, "stdlib.macros.symBodyHash", proc (a: VmArgs) {.nimcall.} =
    let n = getNode(a, 0)
    if n.kind != nkSym:
      stackTrace(c, PStackFrame(prc: c.prc.sym, comesFrom: 0, next: nil), c.exceptionInstr,
                  "symBodyHash() requires a symbol. '" & $n & "' is of kind '" & $n.kind & "'", n.info)
    setResult(a, $symBodyDigest(c.graph, n.sym))

  registerCallback c, "stdlib.macros.isExported", proc(a: VmArgs) {.nimcall.} =
    let n = getNode(a, 0)
    if n.kind != nkSym:
      stackTrace(c, PStackFrame(prc: c.prc.sym, comesFrom: 0, next: nil), c.exceptionInstr,
                  "isExported() requires a symbol. '" & $n & "' is of kind '" & $n.kind & "'", n.info)
    setResult(a, sfExported in n.sym.flags)

  proc hashVmImpl(a: VmArgs) =
    var res = hashes.hash(a.getString(0), a.getInt(1).int, a.getInt(2).int)
    if c.config.cmd == cmdCompileToJS:
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
    if c.config.cmd == cmdCompileToJS:
      # emulate JS's terrible integers:
      res = cast[int32](res)
    setResult(a, res)

  registerCallback c, "stdlib.hashes.hashVmImplByte", hashVmImplByte
  registerCallback c, "stdlib.hashes.hashVmImplChar", hashVmImplByte

  if optBenchmarkVM in c.config.globalOptions:
    wrap0(cpuTime, timesop)
  else:
    proc cpuTime(): float = 5.391245e-44  # Randomly chosen
    wrap0(cpuTime, timesop)
