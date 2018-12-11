#[
test for vmops.nim
]#
import os
import math
import strutils

# proc forceCT()

static:
  # TODO: add more tests
  block: #getAppFilename, gorgeEx, gorge
    let nim = getAppFilename()
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
