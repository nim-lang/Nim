# Copyright (C) Andreas Rumpf. All rights reserved.
# BSD License. Look at license.txt for more info.

## Implements 'nimble publish' to create a pull request against
## nim-lang/packages automatically.

import system except TResult
import httpclient, strutils, json, os, browsers, times, uri
import common, tools, cli, config, options, packageinfotypes
import strformat
{.warning[UnusedImport]: off.}
from net import SslCVerifyMode, newContext

type
  Auth = object
    user: string
    token: string  ## Github access token
    http: HttpClient ## http client for doing API requests

const
  ApiKeyFile = "github_api_token"
  ApiTokenEnvironmentVariable = "NIMBLE_GITHUB_API_TOKEN"
  ReposUrl = "https://api.github.com/repos/"
  defaultBranch = "master" # Default branch on https://github.com/nim-lang/packages

proc userAborted() =
  raise nimbleError("User aborted the process.")

proc createHeaders(a: Auth) =
  a.http.headers = newHttpHeaders({
    "Authorization": "token $1" % a.token,
    "Content-Type": "application/x-www-form-urlencoded",
    "Accept": "*/*"
  })

proc requestNewToken(cfg: Config): string =
  display("Info:", "Please create a new personal access token on Github in" &
          " order to allow Nimble to fork the packages repository.",
          priority = HighPriority)
  display("Hint:", "Make sure to give the access token access to public repos" &
          " (public_repo scope)!", Warning, HighPriority)
  sleep(5000)
  display("Info:", "Your default browser should open with the following URL: " &
          "https://github.com/settings/tokens/new", priority = HighPriority)
  sleep(3000)
  openDefaultBrowser("https://github.com/settings/tokens/new")
  let token = promptCustom("Personal access token?", "").strip()
  # inform the user that their token will be written to disk
  let tokenWritePath = cfg.nimbleDir / ApiKeyFile
  display("Info:", "Writing access token to file:" & tokenWritePath,
          priority = HighPriority)
  writeFile(tokenWritePath, token)
  sleep(3000)
  return token

proc getGithubAuth(o: Options): Auth =
  let cfg = o.config
  let ctx = newSSLContext(o.disableSslCertCheck)
  result.http = newHttpClient(proxy = getProxy(o), sslContext = ctx)
  # always prefer the environment variable to asking for a new one
  if existsEnv(ApiTokenEnvironmentVariable):
    result.token = getEnv(ApiTokenEnvironmentVariable)
    display("Info:", "Using the '" & ApiTokenEnvironmentVariable &
            "' environment variable for the GitHub API Token.",
            priority = HighPriority)
  else:
    # try to read from disk, if it cannot be found write a new one
    try:
      let apiTokenFilePath = cfg.nimbleDir / ApiKeyFile
      result.token = readFile(apiTokenFilePath).strip()
      display("Info:", "Using GitHub API Token in file: " & apiTokenFilePath,
              priority = HighPriority)
    except IOError:
      result.token = requestNewToken(cfg)
  createHeaders(result)
  let resp = result.http.getContent("https://api.github.com/user").parseJson()

  result.user = resp["login"].str
  display("Success:", "Verified as " & result.user, Success, HighPriority)

proc isCorrectFork(j: JsonNode): bool =
  # Check whether this is a fork of the nimble packages repo.
  result = false
  if j{"fork"}.getBool():
    result = j{"parent"}{"full_name"}.getStr() == "nim-lang/packages"

proc forkExists(a: Auth): bool =
  try:
    let x = a.http.getContent(ReposUrl & a.user & "/packages")
    let j = parseJson(x)
    result = isCorrectFork(j)
  except JsonParsingError, IOError:
    result = false

proc createFork(a: Auth) =
  try:
    discard a.http.postContent(ReposUrl & "nim-lang/packages/forks")
  except HttpRequestError:
    raise nimbleError("Unable to create fork. Access token" &
                       " might not have enough permissions.")

proc createPullRequest(a: Auth, pkg: PackageInfo, url, branch: string): string =
  display("Info", "Creating PR", priority = HighPriority)
  let payload = %* {
      "title": &"Add package {pkg.basicInfo.name}",
      "head": &"{a.user}:{branch}",
      "base": defaultBranch,
      "body": &"{pkg.description}\n\n{url}"
  }
  var body = a.http.postContent(ReposUrl & "nim-lang/packages/pulls", $payload)
  var pr = parseJson(body)
  return pr{"html_url"}.getStr()

proc `%`(s: openArray[string]): JsonNode =
  result = newJArray()
  for x in s: result.add(%x)

proc cleanupWhitespace(s: string): string =
  ## Removes trailing whitespace and normalizes line endings to LF.
  result = newStringOfCap(s.len)
  var i = 0
  while i < s.len:
    if s[i] == ' ':
      var j = i+1
      while s[j] == ' ': inc j
      if s[j] == '\c':
        inc j
        if s[j] == '\L': inc j
        result.add '\L'
        i = j
      elif s[j] == '\L':
        result.add '\L'
        i = j+1
      else:
        result.add ' '
        inc i
    elif s[i] == '\c':
      inc i
      if s[i] == '\L': inc i
      result.add '\L'
    elif s[i] == '\L':
      result.add '\L'
      inc i
    else:
      result.add s[i]
      inc i
  if result[^1] != '\L':
    result.add '\L'

proc editJson(p: PackageInfo; url, tags, downloadMethod: string) =
  var contents = parseFile("packages.json")
  doAssert contents.kind == JArray
  contents.add(%*{
    "name": p.basicInfo.name,
    "url": url,
    "method": downloadMethod,
    "tags": tags.split(),
    "description": p.description,
    "license": p.license,
    "web": url
  })
  writeFile("packages.json", contents.pretty.cleanupWhitespace)

proc publish*(p: PackageInfo, o: Options) =
  ## Publishes the package p.
  let auth = getGithubAuth(o)
  var pkgsDir = getNimbleUserTempDir() / "nimble-packages-fork"
  if not forkExists(auth):
    createFork(auth)
    display("Info:", "Waiting 10s to let Github create a fork",
            priority = HighPriority)
    os.sleep(10_000)

    display("Info:", "Finished waiting", priority = LowPriority)
  if dirExists(pkgsDir):
    display("Removing", "old packages fork git directory.",
            priority = LowPriority)
    removeDir(pkgsDir)
  createDir(pkgsDir)
  cd pkgsDir:
    # Avoid git clone to prevent token from being stored in repo
    # https://github.com/blog/1270-easier-builds-and-deployments-using-git-over-https-and-oauth
    display("Copying", "packages fork into: " & pkgsDir, priority = HighPriority)
    doCmd("git init")
    # The repo will have 0 branches created at this point. So the
    # below command will always work.
    doCmd("git checkout -b " & defaultBranch)
    doCmd("git pull https://github.com/" & auth.user & "/packages")
    # Make sure to update the fork
    display("Updating", "the fork", priority = HighPriority)
    doCmd("git pull https://github.com/nim-lang/packages.git " & defaultBranch)
    doCmd("git push https://" & auth.token & "@github.com/" & auth.user & "/packages " & defaultBranch)

  if not dirExists(pkgsDir):
    raise nimbleError(
        "Cannot find nimble-packages-fork git repository. Cloning failed.")

  if not fileExists(pkgsDir / "packages.json"):
    raise nimbleError(
        "No packages file found in cloned fork.")

  # We need to do this **before** the cd:
  # Determine what type of repo this is.
  var url = ""
  var downloadMethod = ""
  if dirExists(os.getCurrentDir() / ".git"):
    let (output, exitCode) = doCmdEx("git ls-remote --get-url")
    if exitCode == 0:
      url = output.strip
      if url.endsWith(".git"): url.setLen(url.len - 4)
      downloadMethod = "git"
    let parsed = parseUri(url)

    if parsed.scheme == "":
      # Assuming that we got an ssh write/read URL.
      let sshUrl = parseUri("ssh://" & url)
      url = "https://" & sshUrl.hostname & "/" & sshUrl.port & sshUrl.path
    elif parsed.username != "" or parsed.password != "":
      # check for any confidential information
      # TODO: Use raiseNimbleError(msg, hintMsg) here
      raise nimbleError(
        "Cannot publish the repository URL because it contains username " &
        "and/or password. Fix the remote URL. Hint: \"git remote -v\"")

  elif dirExists(os.getCurrentDir() / ".hg"):
    downloadMethod = "hg"
    # TODO: Retrieve URL from hg.
  else:
    raise nimbleError(
         "No .git nor .hg directory found. Stopping.")

  if url.len == 0:
    url = promptCustom("Github URL of " & p.basicInfo.name & "?", "")
    if url.len == 0: userAborted()

  let tags = promptCustom(
    "Whitespace separated list of tags? (For example: web library wrapper)",
    ""
  )

  cd pkgsDir:
    editJson(p, url, tags, downloadMethod)
    let branchName = "add-" & p.basicInfo.name & getTime().utc.format("HHmm")
    doCmd("git checkout -B " & branchName)
    doCmd("git commit packages.json -m \"Added package " & p.basicInfo.name & "\"")
    display("Pushing", "to remote of fork.", priority = HighPriority)
    doCmd("git push https://" & auth.token & "@github.com/" & auth.user & "/packages " & branchName)
    let prUrl = createPullRequest(auth, p, url, branchName)
    display("Success:", "Pull request successful, check at " & prUrl , Success, HighPriority)
