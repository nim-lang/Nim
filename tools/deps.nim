import os, uri, strformat, osproc, strutils

proc exec(cmd: string) =
  echo "deps.cmd: " & cmd
  let status = execShellCmd(cmd)
  doAssert status == 0, cmd

proc execEx(cmd: string): tuple[output: TaintedString, exitCode: int] =
  echo "deps.cmd: " & cmd
  execCmdEx(cmd, {poStdErrToStdOut, poUsePath, poEvalCommand})

proc isGitRepo(dir: string): bool =
  # This command is used to get the relative path to the root of the repository.
  # Using this, we can verify whether a folder is a git repository by checking
  # whether the command success and if the output is empty.
  let (output, status) = execEx fmt"git -C {quoteShell(dir)} rev-parse --show-cdup"
  # On Windows there will be a trailing newline on success, remove it.
  # The value of a successful call typically won't have a whitespace (it's
  # usually a series of ../), so we know that it's safe to unconditionally
  # remove trailing whitespaces from the result.
  result = status == 0 and output.strip() == ""

const commitHead* = "HEAD"

proc cloneDependency*(destDirBase: string, url: string, commit = commitHead,
                      appendRepoName = true, allowBundled = false) =
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
  if isGitRepo(destDir):
    exec fmt"git -C {destDir2} fetch -q"
    exec fmt"git -C {destDir2} checkout -q {commit}"
  elif allowBundled:
    discard "this dependency was bundled with Nim, don't do anything"
  else:
    quit "FAILURE: " & destdir & " already exists but is not a git repo"
