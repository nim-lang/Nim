discard """
  joinable: false
"""

import std/[strformat,os,osproc]

proc main() =
  const nim = getCurrentCompilerExe()
  const file = currentSourcePath().parentDir / "mevalffi.nim"
  # strangely, --hint:cc:off was needed
  let cmd = fmt"{nim} c -f --experimental:compiletimeFFI --hints:off --hint:cc:off {file}"
  let (output, exitCode) = execCmdEx(cmd)
  let expected = """
hello world stderr
hi stderr
foo
foo:100
foo:101
foo:102:103
foo:102:103:104
foo:0.03:asdf:103:105
ret={s1:foobar s2:foobar age:25 pi:3.14}
"""
  doAssert output == expected, output
  doAssert exitCode == 0

when defined(nimHasLibFFIEnabled):
  main()
