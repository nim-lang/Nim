discard """
output: '''
main: HELLO!
main: before
main: after
43
main: before
main: after
44
main: before
main: after
45
'''
"""

# this test is expected to be executed with arguments - the full nim compiler
# command used for building it - so it can rebuild iself the same way - example:
# <this_file>.exe nim c --hints:on -d:testing --nimblePath:tests/deps
# -d:release --hotCodeReloading:on --nimCache:<folder> <this_file>.nim

import os, osproc, times #, strutils # let args = commandLineParams()[2..^1].join(" ")

var args: string
for curr in 2..paramCount(): args = args & paramStr(curr) & " "

import nimhcr_0

var vers = [1]
proc update(file: int) =
  proc getfile(mid: string): string =
    let (path, _, _) = splitFile(currentSourcePath())
    return path & "/nimhcr_" & mid & ".nim"
  copyFile(getfile($file & "_" & $vers[file]), getfile($file))
  vers[file].inc

proc compileReloadExecute() =
  let cmd = "nim " & args
  let (stdout, exitcode) = execCmdEx(cmd)
  if exitcode != 0:
    echo "command: ", cmd
    echo stdout
  performCodeReload()
  echo getInt()

beforeCodeReload:
  echo "main: before"

afterCodeReload:
  echo "main: after"

echo "main: HELLO!"

update 0
compileReloadExecute()

update 0
compileReloadExecute()

update 0
compileReloadExecute()
