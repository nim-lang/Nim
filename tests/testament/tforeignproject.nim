discard """
  joinable: false
"""

# bug #16830: outside the Nim repo (no `testament/testament.nim.cfg` in the
# current directory) the categories named after the Nim repo's own suites
# (`examples`, `lib`, `debugger`) run the tests the project has in
# `tests/<category>`, not the Nim repo's examples, stdlib modules or debugger
# tests.
import std/[assertions, os, osproc, strutils, tempfiles]

const nim = getCurrentCompilerExe()
let testament = getCurrentDir() / ("testament" / "testament").addFileExt(ExeExt)
let project = createTempDir("testament_foreign_project_", "")

try:
  for category in ["examples", "lib", "debugger"]:
    createDir(project / "tests" / category)
    writeFile(project / "tests" / category / "tmain.nim", "doAssert true\n")
    let args = [
      testament,
      "--nim:" & nim,
      "--colors:off",
      "--backendLogging:off",
      "cat",
      category,
      "--skipParentCfg",
      "--skipUserCfg",
    ]
    let run = execCmdEx(quoteShellCommand(args), workingDir = project)
    doAssert run.exitCode == 0, category & ": " & run.output
    doAssert ("PASS: tests/" & category & "/tmain.nim") in run.output,
      category & ": " & run.output
finally:
  removeDir(project)
