## Utilities for continous integration
##
## See also: testament/azure.nim

import os, osproc, strformat, strutils
import "."/azure_common

export isAzureCI

proc isPullRequest*(): bool =
  ## returns true if CI build is triggered via a PR
  ## else, it corresponds to a direct push to the repository by owners
  assert isAzureCI()
  getAzureEnv("Build.Reason") == "PullRequest"

proc runCmd(cmd: string) =
  echo "runCmd: " & cmd
  let status = execShellCmd(cmd)
  doAssert status == 0, $status

proc tryRunCmd(cmd: string): bool =
  echo "tryRunCmd: " & cmd
  execShellCmd(cmd) == 0

proc gitLogPretty(): string =
  ## last commit msg excluding merge commit, so that it works both for PR's
  ## and direct pushes to repo
  let cmd = "git log --no-merges -1 --pretty=oneline"
  let (outp, errC) = execCmdEx(cmd)
  doAssert errC == 0, $outp
  outp

proc isNimDocOnly*(): bool =
  # TODO: support windows
  "[nimDocOnly]" in gitLogPretty()

proc installNode*() =
  echo "installNode"
  when defined(osx):
    if not tryRunCmd "brew install node  > /dev/null":
      echo " ok to ignore this: Error: The `brew link` step did not complete successfully"
      runCmd "brew link --overwrite node"
  elif defined(linux):
    # https://linuxize.com/post/how-to-install-node-js-on-ubuntu-18.04/
    template suppress(a): untyped =
      a & " > /dev/null 2>&1"
    runCmd "curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -".suppress
    runCmd "sudo apt install -yqq nodejs".suppress
    runCmd "nodejs --version"
  elif defined(windows):
    # should've be installed via azure-pipelines.yml, but could do it here too
    # via https://nodejs.org/en/download/
    discard
  runCmd "node --version"

proc hostInfo*(): string =
  result = fmt"hostOS: {hostOS}, hostCPU: {hostCPU}, nproc: {countProcessors()}, int: {int.sizeof}, float: {float.sizeof}, cpuEndian: {cpuEndian}, cwd: {getCurrentDir()}"
  if not isAzureCI(): return
  let mode = if existsEnv("NIM_COMPILE_TO_CPP"): "cpp" else: "c"

  var urlBase = getAzureEnv("Build.Repository.Uri")
  var urlPR = ""

  let isPR = isPullRequest()
  let commit = getAzureEnv("Build.SourceVersion")
  if isPR:
    let id = getAzureEnv("System.PullRequest.PullRequestNumber")
    urlPR = fmt"{urlBase}/pull/{id}"
  let urlCommit = fmt"{urlBase}/commit/{commit}"

  let branch = getAzureEnv("Build.SourceBranchName")
  # let msg = getAzureEnv("Build.SourceVersionMessage") # not useful for merge commits
  let msg = gitLogPretty()
  let buildNum = getAzureEnv("Build.BuildNumber")
  let nl = "\n"
  # Avoids `,` after urls since it'd prevent the link from being clickable in azure UI
  result.add fmt"""{nl}urlPR: {urlPR}{nl}urlCommit: {urlCommit}{nl}branch: {branch}, mode: {mode}, buildNum: {buildNum}{nl}msg: {msg}{nl}"""
