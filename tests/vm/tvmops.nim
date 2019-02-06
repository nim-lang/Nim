#[
test for vmops.nim
]#
import os
import math
import strutils
import "$nim/testament/lib/stdtest/specialpaths"

template forceConst(a: untyped): untyped =
  ## Force evaluation at CT, useful for example here:
  ## `callFoo(forceConst(getBar1()), getBar2())`
  ## instead of:
  ##  block:
  ##    const a = getBar1()
  ##    `callFoo(a, getBar2())`
  const ret = a
  ret

const tempFile = buildDir / "D20190206T151011.txt"

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

  block: # putEnv, existsEnv, getEnv
    const key = "D20181210T175037"
    const val = "foo"
    putEnv(key, val)
    doAssert existsEnv(key)
    doAssert getEnv(key) == val

  block: # std/io, std/os
    let content = "this is " & tempFile
    writeFile tempFile, content
    let content2 = readFile tempFile
    doAssert content == content2, $(tempFile, content, content2)

  block: # arcsin
    # sanity check (we probably don't need to test for all ops)
    const a1 = arcsin 0.3
    let a2 = arcsin 0.3
    doAssert a1 == a2

block:
  # Check against bugs like #9176
  doAssert getCurrentCompilerExe() == forceConst(getCurrentCompilerExe())
  if false: #pending #9176
    doAssert gorgeEx("unexistant") == forceConst(gorgeEx("unexistant"))

block: # cleanup
  if existsFile tempFile: removeFile tempFile
