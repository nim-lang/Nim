import os

template getScriptDir(): string =
  parentDir(instantiationInfo(-1, true).filename)

const
  execName = when defined(windows): "tgorge.bat" else: "./tgorge.sh"
  relOutput = gorge(execName)
  absOutput = gorge(getScriptDir() / execName)

doAssert relOutput == "gorge test"
doAssert absOutput == "gorge test"