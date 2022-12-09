discard """
  cmd: "nim c --experimental:vmopsDanger -r $file"
"""
import std/assertions
import times

const foo = getTime()
let bar = foo
doAssert bar > low(Time)
