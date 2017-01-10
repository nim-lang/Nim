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
  floor, ceil, fmod

from os import getEnv, existsEnv, dirExists, fileExists, walkDir

template mathop(op) {.dirty.} =
  registerCallback(c, "stdlib.math." & astToStr(op), `op Wrapper`)

template osop(op) {.dirty.} =
  registerCallback(c, "stdlib.os." & astToStr(op), `op Wrapper`)

template systemop(op) {.dirty.} =
  registerCallback(c, "stdlib.system." & astToStr(op), `op Wrapper`)

template wrap1f_math(op) {.dirty.} =
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    setResult(a, op(getFloat(a, 0)))
  mathop op

template wrap2f_math(op) {.dirty.} =
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    setResult(a, op(getFloat(a, 0), getFloat(a, 1)))
  mathop op

template wrap1s_os(op) {.dirty.} =
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    setResult(a, op(getString(a, 0)))
  osop op

template wrap1s_system(op) {.dirty.} =
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    setResult(a, op(getString(a, 0)))
  systemop op

template wrap2svoid_system(op) {.dirty.} =
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    op(getString(a, 0), getString(a, 1))
  systemop op

proc getCurrentExceptionMsgWrapper(a: VmArgs) {.nimcall.} =
  setResult(a, if a.currentException.isNil: ""
               else: a.currentException.sons[3].skipColon.strVal)

proc staticWalkDirImpl(path: string, relative: bool): PNode =
  result = newNode(nkBracket)
  for k, f in walkDir(path, relative):
    result.add newTree(nkPar, newIntNode(nkIntLit, k.ord),
                              newStrNode(nkStrLit, f))

proc gorgeExWrapper(a: VmArgs) {.nimcall.} =
  let (s, e) = opGorge(getString(a, 0), getString(a, 1), getString(a, 2),
                       a.currentLineInfo)
  setResult a, newTree(nkPar, newStrNode(nkStrLit, s), newIntNode(nkIntLit, e))

proc registerAdditionalOps*(c: PCtx) =
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
  wrap2f_math(fmod)

  wrap1s_os(getEnv)
  wrap1s_os(existsEnv)
  wrap1s_os(dirExists)
  wrap1s_os(fileExists)
  wrap2svoid_system(writeFile)
  wrap1s_system(readFile)
  systemop getCurrentExceptionMsg
  registerCallback c, "stdlib.*.staticWalkDir", proc (a: VmArgs) {.nimcall.} =
    setResult(a, staticWalkDirImpl(getString(a, 0), getBool(a, 1)))
  systemop gorgeEx
