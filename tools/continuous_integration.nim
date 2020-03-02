import os, osproc, strutils, strformat

proc isAzureCI*(): bool =
  getEnv("NIM_CI_Build_SourceBranchName").len > 0

import macros

macro fun(ret: var string, body): untyped =
  result = newStmtList()
  for a in body:
    let a2 = a.strVal
    result.add quote do:
      `ret`.add `a2` & ": " & getEnv(`a2`) & "\n"

proc isPullRequest*(): bool =
  ## returns true if CI build is triggered via a PR
  ## else, it corresponds to a direct push to the repository by owners
  assert isAzureCI()
  getEnv("NIM_CI_Build_Reason") == "PullRequest"

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
    # node: v12.16.0
    # nodejs: v10.19.0

  elif defined(windows):
    # should've be installed via azure-pipelines.yml, but could do it here too
    # via https://nodejs.org/en/download/
    discard

  runCmd "node --version"

proc hostInfo*(): string =
  echo "D20200301T212950.v5"
  result = "hostOS: $1, hostCPU: $2, nproc: $3, int: $4, float: $5, cpuEndian: $6, cwd: $7" %
    [hostOS, hostCPU, $countProcessors(),
     $int.sizeof, $float.sizeof, $cpuEndian, getCurrentDir()]
  if not isAzureCI(): return
  let mode = if existsEnv("NIM_COMPILE_TO_CPP"): "cpp" else: "c"

  var url = getEnv("NIM_CI_Build_Repository_Uri")
  let isPR = isPullRequest()
  let commit = getEnv("NIM_CI_Build_SourceVersion")
  if isPR:
    url = "$1/pull/$2" % [url, getEnv("NIM_CI_PR_PullRequestNumber")]
  else:
    url = "$1/commit/$2" % [url, commit]

  let branch = getEnv("NIM_CI_Build_SourceBranchName")
  let msg = getEnv("NIM_CI_Build_SourceVersionMessage").quoteShell
  let attempt = getEnv("NIM_CI_JobAttempt")
  let buildNum = getEnv("NIM_CI_Build_BuildNumber")
  # getEnv("NIM_CI_TeamProject")
  result.add """isPR:{isPR}, url: {url}, branch: {branch}, commit: {commit}, msg: {msg}, mode: {mode}, buildNum: {buildNum}"""
  result.add "\n"

  fun(result):
    NIM_CI_PR_SourceRepositoryURI
    NIM_CI_PR_PullRequestNumber
    NIM_CI_TeamProject
    NIM_CI_JobAttempt
    NIM_CI_Build_ArtifactStagingDirectory
    NIM_CI_Build_BuildId
    NIM_CI_Build_BuildNumber
    NIM_CI_Build_BuildUri
    NIM_CI_Build_BinariesDirectory
    NIM_CI_Build_DefinitionName
    NIM_CI_Build_Repository_ID
    NIM_CI_Build_Repository_Name
    NIM_CI_Build_Repository_Provider
    NIM_CI_Build_Repository_Uri
    NIM_CI_Build_SourceBranch
    NIM_CI_Build_SourceBranchName
    NIM_CI_Build_SourcesDirectory
    NIM_CI_Build_SourceVersion
    NIM_CI_Build_SourceVersionMessage
    NIM_CI_Build_Reason

  result.add "\n"
