import os, uri, strformat

proc exec(cmd: string) =
  echo "deps.cmd: " & cmd
  let status = execShellCmd(cmd)
  doAssert status == 0, cmd

const commitHead* = "HEAD"

proc cloneDependency*(destDirBase: string, url: string, commit = commitHead, appendRepoName = true) =
  let destDirBase = destDirBase.absolutePath
  let p = url.parseUri.path
  let name = p.splitFile.name
  var destDir = destDirBase
  if appendRepoName: destDir = destDir / name
  let destDir2 = destDir.quoteShell
  if not dirExists(destDir):
    # note: old code used `destDir / .git` but that wouldn't prevent git clone
    # from failing
    exec fmt"git clone -q {url} {destDir2}"
  exec fmt"git -C {destDir2} fetch -q"
  exec fmt"git -C {destDir2} checkout -q {commit}"
