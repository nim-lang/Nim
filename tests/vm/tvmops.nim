#[
test for vmops.nim
]#
import os
import math
import strutils
import strformat

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
    let ret2 = gorgeEx(nim & " --nonexistant")
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
    doAssert gorgeEx("nonexistant") == forceConst(gorgeEx("nonexistant"))

block: # PR #13714 VM callbacks can now raise
  proc test() =
    doAssertRaises(IOError): writeFile("nonexistant/bar.txt".unixToNativePath, "foo")
    doAssertRaises(OSError): (for a in walkDir("nonexistant", checkDir = true): discard)
    const file = "nonexistant/bar.txt".unixToNativePath
    proc fun1() = writeFile(file, "foo")
    proc fun2()=fun1()
    proc fun3() =
      var msg: string
      try: fun2()
      except Exception as e:
        msg = e.msg
        # BUG: e.getStacktrace doesn't show same as when exception is not caught,
        # hence `testStacktrace` below
      doAssert msg.contains "cannot open: " & file
    fun3()

  static: test()
  test()

  proc testStacktrace() =
    const cmd = fmt"{getCurrentCompilerExe()} c --hints:off --listfullpaths:off mvmops.nim"
    const (output, exitCode) = gorgeEx(cmd)
    doAssert exitCode != 0
    # could reuse tassert_c.tmatch for a more precise test, or pegs
    let expected = """
stack trace: (most recent call last)
mvmops.nim(4, 13)        mvmops
mvmops.nim(3, 17)        fun2
mvmops.nim(2, 24)        fun1
"""
    doAssert expected in output
