## Utilities for continous integration
##
## See also: testament/azure.nim
## We avoid dependency on testament since this is imported by koch
## Alternatively, testament/azure.nim could import this instead.

import os, osproc, strformat

proc isAzureCI*(): bool =
  # existsEnv("BUILD_SOURCEBRANCHNAME")
    # this would have benefit that we're
    # explicitly setting this variable in azure-pipelines.yml
  existsEnv("TF_BUILD") # factor with specs.isAzure

proc isPullRequest*(): bool =
  ## returns true if CI build is triggered via a PR
  ## else, it corresponds to a direct push to the repository by owners
  assert isAzureCI()
  # see https://docs.microsoft.com/en-us/azure/devops/pipelines/build/variables?view=azure-devops&tabs=yaml
  # for what gets exported, eg $(System.PullRequest.PullRequestNumber) => SYSTEM_PULLREQUEST_PULLREQUESTNUMBER
  getEnv("BUILD_REASON") == "PullRequest"

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

  # var url = getEnv("Build_Repository_Uri")
  var url = getEnv("BUILD_REPOSITORY_URI")

  let isPR = isPullRequest()
  let commit = getEnv("BUILD_SOURCEVERSION")
  if isPR:
    let id = getEnv("SYSTEM_PULLREQUEST_PULLREQUESTNUMBER")
    url = fmt"{url}/pull/{id}"
  else:
    url = fmt"{url}/commit/{commit}"

  let branch = getEnv("BUILD_SOURCEBRANCHNAME")
  let msg = getEnv("BUILD_SOURCEVERSIONMESSAGE").quoteShell
  let buildNum = getEnv("BUILD_BUILDNUMBER")
  let nl = "\n"
  result.add fmt"""{nl}isPR:{isPR}, url: {url}, branch: {branch}, commit: {commit}, mode: {mode}, buildNum: {buildNum}{nl}msg: {msg}{nl}"""
