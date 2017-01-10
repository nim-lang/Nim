import os

template getScriptDir(): string =
  parentDir(instantiationInfo(-1, true).filename)

block gorge:
  const
    execName = when defined(windows): "tgorge.bat" else: "./tgorge.sh"
    relOutput = gorge(execName)
    absOutput = gorge(getScriptDir() / execName)

  doAssert relOutput == "gorge test"
  doAssert absOutput == "gorge test"

block gorgeEx:
  const
    execName = when defined(windows): "tgorgeex.bat" else: "./tgorgeex.sh"
    res = gorgeEx(execName)
  doAssert res.output == "gorgeex test"
  doAssert res.exitCode == 1
