#[
test for vmops.nim
]#
import os
import math
import strutils
from macros import getProjectPath

template forceConst(a: untyped): untyped =
  ## Force evaluation at CT, useful for example here:
  ## `callFoo(forceConst(getBar1()), getBar2())`
  ## instead of:
  ##  block:
  ##    const a = getBar1()
  ##    `callFoo(a, getBar2())`
  const ret = a
  ret

template testIssue9176(a: untyped): untyped =
  ## Check against bugs like #9176
  doAssert a == forceConst(a)
  # sanity check: make sure it's not empty either
  var a2: type(a)
  doAssert a != a2

static:
  # TODO: add more tests
  block: #getAppFilename, gorgeEx, gorge
    const nim = getCurrentCompilerExe()
    let cmd = nim & " --version"
    let ret = gorgeEx(cmd)
    doAssert ret.exitCode == 0
    doAssert ret.output.contains "Nim Compiler"
    let ret2 = gorgeEx(nim & " --unexistant")
    doAssert ret2.exitCode != 0
    let output3 = gorge(cmd)
    doAssert output3 == ret.output
    doAssert staticExec(cmd) == ret.output

  block:
    const key = "D20181210T175037"
    const val = "foo"
    putEnv(key, val)
    doAssert existsEnv(key)
    doAssert getEnv(key) == val

  block:
    # sanity check (we probably don't need to test for all ops)
    const a1 = arcsin 0.3
    let a2 = arcsin 0.3
    doAssert a1 == a2

block:
  testIssue9176 getCurrentCompilerExe()
  testIssue9176 getProjectPath()
  testIssue9176 currentSourcePath()
  testIssue9176 gorgeEx("unexistant")
