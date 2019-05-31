#[
test for vmops.nim
]#
import os
import math
import strutils

template forceConst(a: untyped): untyped =
  ## Force evaluation at CT, useful for example here:
  ## `callFoo(forceConst(getBar1()), getBar2())`
  ## instead of:
  ##  block:
  ##    const a = getBar1()
  ##    `callFoo(a, getBar2())`
  const ret = a
  ret

static:
  # TODO: add more tests
  block: #getAppFilename, gorgeEx, gorge
    const nim = getCurrentCompilerExe()
    let ret = gorgeEx(nim & " --version")
    doAssert ret.exitCode == 0
    doAssert ret.output.contains "Nim Compiler"
    let ret2 = gorgeEx(nim & " --unexistant")
    doAssert ret2.exitCode != 0
    let output3 = gorge(nim & " --version")
    doAssert output3.contains "Nim Compiler"

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

  block bitxor:
    let x = -1'i32
    let y = 1'i32
    doAssert (x xor y) == -2

block:
  # Check against bugs like #9176
  doAssert getCurrentCompilerExe() == forceConst(getCurrentCompilerExe())
  if false: #pending #9176
    doAssert gorgeEx("unexistant") == forceConst(gorgeEx("unexistant"))
