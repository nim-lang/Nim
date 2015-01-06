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

from os import getEnv, existsEnv, dirExists, fileExists

template mathop(op) {.immediate, dirty.} =
  registerCallback(c, "stdlib.math." & astToStr(op), `op Wrapper`)

template osop(op) {.immediate, dirty.} =
  registerCallback(c, "stdlib.os." & astToStr(op), `op Wrapper`)

template systemop(op) {.immediate, dirty.} =
  registerCallback(c, "stdlib.system." & astToStr(op), `op Wrapper`)

template wrap1f(op) {.immediate, dirty.} =
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    setResult(a, op(getFloat(a, 0)))
  mathop op

template wrap2f(op) {.immediate, dirty.} =
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    setResult(a, op(getFloat(a, 0), getFloat(a, 1)))
  mathop op

template wrap1s(op) {.immediate, dirty.} =
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    setResult(a, op(getString(a, 0)))
  osop op

template wrap2svoid(op) {.immediate, dirty.} =
  proc `op Wrapper`(a: VmArgs) {.nimcall.} =
    op(getString(a, 0), getString(a, 1))
  systemop op

proc getCurrentExceptionMsgWrapper(a: VmArgs) {.nimcall.} =
  setResult(a, if a.currentException.isNil: ""
               else: a.currentException.sons[2].strVal)

proc registerAdditionalOps*(c: PCtx) =
  wrap1f(sqrt)
  wrap1f(ln)
  wrap1f(log10)
  wrap1f(log2)
  wrap1f(exp)
  wrap1f(round)
  wrap1f(arccos)
  wrap1f(arcsin)
  wrap1f(arctan)
  wrap2f(arctan2)
  wrap1f(cos)
  wrap1f(cosh)
  wrap2f(hypot)
  wrap1f(sinh)
  wrap1f(sin)
  wrap1f(tan)
  wrap1f(tanh)
  wrap2f(pow)
  wrap1f(trunc)
  wrap1f(floor)
  wrap1f(ceil)
  wrap2f(fmod)

  wrap1s(getEnv)
  wrap1s(existsEnv)
  wrap1s(dirExists)
  wrap1s(fileExists)
  wrap2svoid(writeFile)
  systemop getCurrentExceptionMsg
