## OS utilities like 'withDir'.
## (c) 2021 Andreas Rumpf

import os, strutils, osproc

proc isUrl*(x: string): bool =
  x.startsWith("git://") or x.startsWith("https://") or x.startsWith("http://")

proc cloneUrl*(url, dest: string; cloneUsingHttps: bool): string =
  ## Returns an error message on error or else "".
  result = ""
  var modUrl =
    if url.startsWith("git://") and cloneUsingHttps:
      "https://" & url[6 .. ^1]
    else: url

  # github + https + trailing url slash causes a
  # checkout/ls-remote to fail with Repository not found
  var isGithub = false
  if modUrl.contains("github.com") and modUrl.endsWith("/"):
    modUrl = modUrl[0 .. ^2]
    isGithub = true

  let (_, exitCode) = execCmdEx("git ls-remote --quiet --tags " & modUrl)
  var xcode = exitCode
  if isGithub and exitCode != QuitSuccess:
    # retry multiple times to avoid annoying github timeouts:
    for i in 0..4:
      os.sleep(4000)
      xcode = execCmdEx("git ls-remote --quiet --tags " & modUrl)[1]
      if xcode == QuitSuccess: break

  if xcode == QuitSuccess:
    # retry multiple times to avoid annoying github timeouts:
    let cmd = "git clone " & modUrl & " " & dest
    for i in 0..4:
      if execShellCmd(cmd) == 0: return ""
      os.sleep(4000)
    result = "exernal program failed: " & cmd
  elif not isGithub:
    let (_, exitCode) = execCmdEx("hg identify " & modUrl)
    if exitCode == QuitSuccess:
      let cmd = "hg clone " & modUrl & " " & dest
      for i in 0..4:
        if execShellCmd(cmd) == 0: return ""
        os.sleep(4000)
      result = "exernal program failed: " & cmd
    else:
      result = "Unable to identify url: " & modUrl
  else:
    result = "Unable to identify url: " & modUrl
