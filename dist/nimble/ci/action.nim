import std/[os, uri, strformat, strutils]
import std/private/gitutils

when defined(nimPreviewSlimSystem):
  import std/assertions

proc exec(cmd: string) =
  echo "deps.cmd: " & cmd
  let status = execShellCmd(cmd)
  doAssert status == 0, cmd

proc execRetry(cmd: string) =
  let ok = retryCall(call = block:
    let status = execShellCmd(cmd)
    let result = status == 0
    if not result:
      echo fmt"failed command: '{cmd}', status: {status}"
    result)
  doAssert ok, cmd

proc cloneDependency(destDirBase: string, url: string, commit = commitHead,
                      appendRepoName = true) =
  let destDirBase = destDirBase.absolutePath
  let p = url.parseUri.path
  let name = p.splitFile.name
  var destDir = destDirBase
  if appendRepoName: destDir = destDir / name
  let quotedDestDir = destDir.quoteShell
  if not dirExists(destDir):
    # note: old code used `destDir / .git` but that wouldn't prevent git clone
    # from failing
    execRetry fmt"git clone -q {url} {quotedDestDir}"
  if isGitRepo(destDir):
    let oldDir = getCurrentDir()
    setCurrentDir(destDir)
    try:
      execRetry "git fetch -q"
      exec fmt"git checkout -q {commit}"
    finally:
      setCurrentDir(oldDir)
  else:
    quit "FAILURE: " & destdir & " already exists but is not a git repo"

proc command =
  const distDir = "dist"
  const commit = "3fa15df7d27ecef624ed932d60f63d6a8949618d"
  cloneDependency(distDir, "https://github.com/nim-lang/checksums.git", commit)

command()
