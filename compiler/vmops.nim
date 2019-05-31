#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Unforunately this cannot be a module yet:
#import vmdeps, vm
from math import sqrt, ln, log10, log2, exp, round, arccos, arcsin,
  arctan, arctan2, cos, cosh, hypot, sinh, sin, tan, tanh, pow, trunc,
  floor, ceil, `mod`

from os import getEnv, existsEnv, dirExists, fileExists, putEnv, walkDir, getAppFilename
from md5 import getMD5
from sighashes import symBodyDigest

template mathop(op) {.dirty.} =
  registerCallback(c, "stdlib.math." & astToStr(op), `op Wrapper`)

template osop(op) {.dirty.} =
  registerCallback(c, "stdlib.os." & astToStr(op), `op Wrapper`)

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

proc getCurrentExceptionMsgWrapper(a: VmArgs) {.nimcall.} =
  setResult(a, if a.currentException.isNil: ""
               else: a.currentException.sons[3].skipColon.strVal)

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
    wrap2svoid(writeFile, ioop)
    wrap1s(readFile, ioop)
    wrap2si(readLines, ioop)
    systemop getCurrentExceptionMsg
    registerCallback c, "stdlib.*.staticWalkDir", proc (a: VmArgs) {.nimcall.} =
      setResult(a, staticWalkDirImpl(getString(a, 0), getBool(a, 1)))
    systemop gorgeEx
  macrosop getProjectPath

  registerCallback c, "stdlib.os.getCurrentCompilerExe", proc (a: VmArgs) {.nimcall.} =
    setResult(a, getAppFilename())

  registerCallback c, "stdlib.macros.symBodyHash", proc (a: VmArgs) {.nimcall.} =
    let n = getNode(a, 0)
    if n.kind != nkSym: raise newException(ValueError, "node is not a symbol")
    setResult(a, $symBodyDigest(c.graph, n.sym))
