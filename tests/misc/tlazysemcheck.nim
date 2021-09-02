discard """
  joinable: false
"""

import std/[osproc, os, strformat, compilesettings, strutils]

const
  nim = getCurrentCompilerExe()
  mode = querySetting(backend)

proc run(opt: string): string =
  let file = "tests/misc/mlazysemcheck.nim"
  let cmd = fmt"{nim} {mode} --hint:all:off {opt} {file}"
  let (ret, status) = execCmdEx(cmd)
  # echo fmt("{opt=}")
  doAssert status == 0, fmt("{cmd=}\n{ret=}")
  result = ret

proc check(opt: string, expected: string) =
  let actual = run(opt)
  # use unittest.check pending https://github.com/nim-lang/Nim/pull/10558
  doAssert expected in actual, fmt("{opt=}\n{actual=}\n{expected=}")

proc main =
  for opt in "-d:case_noimports; -d:case_reordering; -d:case_stdlib ; -d:case_stdlib_imports; -d:case_import1; -d:case_cyclic; -d:case_perf".split(";"):
    check(opt): "" # we can add per-test expectations on compiler output here, e.g. to ensure certain APIs were (or not) compiled
main()
