## Utilities for continous integration
##
## See also: testament/azure.nim

import os, osproc, strformat
import "."/azure_common

export isAzureCI

proc isPullRequest*(): bool =
  ## returns true if CI build is triggered via a PR
  ## else, it corresponds to a direct push to the repository by owners
  assert isAzureCI()
  getEnv("Build.Reason") == "PullRequest"

proc runCmd(cmd: string) =
  echo "runCmd: " & cmd
  let status = execShellCmd(cmd)
  doAssert status == 0, $status

proc tryRunCmd(cmd: string): bool =
  echo "tryRunCmd: " & cmd
  execShellCmd(cmd) == 0

proc installNode*() =
  echo "installNode"
  when defined(osx):
    if not tryRunCmd "brew install node  > /dev/null":
      echo " ok to ignore this: Error: The `brew link` step did not complete successfully"
      runCmd "brew link --overwrite node"
  elif defined(linux):
    # https://linuxize.com/post/how-to-install-node-js-on-ubuntu-18.04/
    runCmd "curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -"
    runCmd "sudo apt install -yq nodejs"
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

  var url = getEnv("Build.Repository.Uri")

  let isPR = isPullRequest()
  let commit = getEnv("Build.SourceVersion")
  if isPR:
    let id = getEnv("System.PullRequest.PullRequestNumber")
    url = fmt"{url}/pull/{id}"
  else:
    url = fmt"{url}/commit/{commit}"

  let branch = getEnv("Build.SourceBranchName")
  let msg = getEnv("Build.SourceVersionMessage").quoteShell
  let buildNum = getAzureEnv("Build.BuildNumber")
  let nl = "\n"
  result.add fmt"""{nl}isPR:{isPR}, url: {url}, branch: {branch}, commit: {commit}, mode: {mode}, buildNum: {buildNum}{nl}msg: {msg}{nl}"""
