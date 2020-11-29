import std/[strformat,os,osproc]
import stdtest/unittest_light

proc main(opt: string, expected: string) =
  const nim = getCurrentCompilerExe()
  const file = currentSourcePath().parentDir / "mstackframes.nim"
  let cmd = fmt"{nim} c -r --excessiveStackTrace:off --stacktraceMsgs:{opt} --hints:off {file}"
  let (output, exitCode) = execCmdEx(cmd)
  assertEquals output, expected
  doAssert exitCode == 0

main("on"): """
mstackframes.nim(38)     mstackframes
mstackframes.nim(29)     main
  z: 0
  z: 1
mstackframes.nim(20)     main2 ("main2", 5, 1)
mstackframes.nim(20)     main2 ("main2", 4, 2)
mstackframes.nim(20)     main2 ("main2", 3, 3)
mstackframes.nim(19)     main2 ("main2", 2, 4)
mstackframes.nim(18)     bar ("bar ",)

"""

main("off"): """
mstackframes.nim(38)     mstackframes
mstackframes.nim(29)     main
mstackframes.nim(20)     main2
mstackframes.nim(20)     main2
mstackframes.nim(20)     main2
mstackframes.nim(19)     main2
mstackframes.nim(18)     bar

"""
