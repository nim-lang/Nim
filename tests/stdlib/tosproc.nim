discard """
  output: ""
"""
# test the osproc module

import os, osproc

block execProcessTest:
  let dir = parentDir(currentSourcePath())
  let (outp, err) = execCmdEx("nim c " & quoteShell(dir / "osproctest.nim"))
  doAssert err == 0
  let exePath = dir / addFileExt("osproctest", ExeExt)
  let outStr1 = execProcess(exePath, workingDir=dir, args=["foo", "b A r"], options={})
  doAssert outStr1 == dir & "\nfoo\nb A r\n"

  const testDir = "t e st"
  createDir(testDir)
  doAssert dirExists(testDir)
  let outStr2 = execProcess(exePath, workingDir=testDir, args=["x yz"], options={})
  doAssert outStr2 == absolutePath(testDir) & "\nx yz\n"

  removeDir(testDir)
  removeFile(exePath)
