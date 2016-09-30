import strtabs, os, osproc, vccenv

when defined(release):
  let vccOptions = { poParentStreams }
else:
  let vccOptions = { poEchoCmd, poParentStreams }

when isMainModule:
  var vccEnvStrTab: StringTableRef = nil
  when defined(i386):
    vccEnvStrTab = getVccEnv "x86"
  when defined(amd64):
    vccEnvStrTab = getVccEnv "amd64"
  when defined(arm):
    vccEnvStrTab = getVccEnv "arm"
  if vccEnvStrTab != nil:
    for vccEnvKey, vccEnvVal in vccEnvStrTab:
      putEnv(vccEnvKey, vccEnvVal)
  let vccProcess = startProcess(
      "link".addFileExt(ExeExt), 
      args = commandLineParams(),
      options = vccOptions
    )
  quit vccProcess.waitForExit()
    
