import os, uri, strformat

proc exec(cmd: string) =
  echo "deps.cmd: " & cmd
  let status = execShellCmd(cmd)
  doAssert status == 0, cmd

const commitHead* = "HEAD"

proc cloneDependency*(destDirBase: string, url: string, commit: string) =
  let destDirBase = destDirBase.absolutePath
  let p = parseUri(uri).path
  let name = p.path.splitFile.name
  let destDir = destDirBase / name
  if not dirExists(destDir):
    exec fmt"git clone -q {url} {destDir}"
  withDir destDir:
    exec "git fetch"
    exec "git checkout " & commit
