discard """
  output: "ok"
  joinable: false
  disabled: "windows"
"""

import std/[os, osproc]

const compiler = getCurrentCompilerExe()

proc main() =
  let fixtureDir = currentSourcePath.parentDir / "nim_native_dynlib"
  let previousCompiler = getEnv("NIM_NATIVE_DYNLIB_COMPILER")
  putEnv("NIM_NATIVE_DYNLIB_COMPILER", compiler)
  defer:
    if previousCompiler.len == 0:
      delEnv("NIM_NATIVE_DYNLIB_COMPILER")
    else:
      putEnv("NIM_NATIVE_DYNLIB_COMPILER", previousCompiler)

  let (output, exitCode) = execCmdEx(
    "sh " & quoteShell(fixtureDir / "build_e2e.sh"),
    workingDir = fixtureDir)
  doAssert exitCode == 0, output
  echo "ok"

main()
