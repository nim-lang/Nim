import strutils, strtabs, os, osproc, vccenv

when defined(release):
  let vccOptions = {poParentStreams}
else:
  let vccOptions = {poEchoCmd, poParentStreams}

const 
  platformPrefix = "--platform"
  winstorePrefix = "--winstore"
  sdkversionPrefix = "--sdkversion"

  platformSepIdx = platformPrefix.len
  sdkversionSepIdx = sdkversionPrefix.len
  
  HelpText = """
+-----------------------------------------------------------------+
|         Microsoft C/C++ compiler wrapper for Nim                |
|             (c) 2016 Fredrik Høisæther Rasch                    |
+-----------------------------------------------------------------+

Usage:
  vccexe [options] [compileroptions]
Options:
  --platform:<arch>   Specify the Compiler Platform Tools architecture
                      <arch>: x86 | amd64 | arm | x86_amd64 | x86_arm | amd64_x86 | amd64_arm
  --winstore          Use Windows Store (rather than desktop) development tools
  --sdkversion:<v>    Use a specific Windows SDK version:
                      <v> is either the full Windows 10 SDK version number or 
                      "8.1" to use the windows 8.1 SDK

Other command line arguments are passed on to the
Microsoft C/C++ compiler for the specified SDK toolset
"""

when isMainModule:
  var platformArg: string = nil
  var sdkVersionArg: string = nil
  var storeArg: bool = false

  var clArgs: seq[TaintedString] = @[]

  var wrapperArgs = commandLineParams()
  for wargv in wrapperArgs:
    # Check whether the current argument contains -- prefix
    if wargv.startsWith(platformPrefix): # Check for platform
      platformArg = wargv.substr(platformSepIdx + 1)
    elif wargv == winstorePrefix: # Check for winstore
      storeArg = true
    elif wargv.startsWith(sdkversionPrefix): # Check for sdkversion
      sdkVersionArg = wargv.substr(sdkversionSepIdx + 1)
    else: # Regular cl.exe argument -> store for final cl.exe invocation
      if (wargv.len == 2) and (wargv[1] == '?'):
        echo HelpText
      clArgs.add(wargv)

  var vccEnvStrTab = getVccEnv(platformArg, storeArg, sdkVersionArg)  
  if vccEnvStrTab != nil:
    for vccEnvKey, vccEnvVal in vccEnvStrTab:
      putEnv(vccEnvKey, vccEnvVal)
  let vccProcess = startProcess(
      "cl.exe",
      args = clArgs,
      options = vccOptions
    )
  quit vccProcess.waitForExit()
