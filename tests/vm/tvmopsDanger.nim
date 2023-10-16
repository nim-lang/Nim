discard """
  cmd: "nim c --experimental:vmopsDanger -r $file"
"""
when defined(nimPreviewSlimSystem):
  import std/assertions
import std/times

const foo = getTime()
let bar = foo
doAssert bar > low(Time)