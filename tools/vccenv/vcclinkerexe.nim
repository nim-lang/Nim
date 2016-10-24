import strutils, strtabs, os, osproc, vccenv

when defined(release):
  let vccOptions = {poParentStreams}
else:
  let vccOptions = {poEchoCmd, poParentStreams}

const 
  vcvarsArgPrefix = "vcvars:"
  platformArgPrefix = "platform:"
  storeArgPrefix = "store"
  sdkArgPrefix = "sdk:"
  vcvarsArgIdx = 1   # vcvars comes after - or / char in argument
  argsToken1Idx = vcvarsArgIdx + vcvarsArgPrefix.len 
  platformArgValueIdx = argsToken1Idx + platformArgPrefix.len
  sdkArgValueIdx = argsToken1Idx + sdkArgPrefix.len

  HelpText = """
+-----------------------------------------------------------------+
|         Microsoft C/C++ compiler wrapper for Nim                |
|             (c) 2016 Fredrik Høisæther Rasch                    |
+-----------------------------------------------------------------+

Usage:
  vccexe [options] [compileroptions]
Options:
  /vcvars:platform:<arch>   Specify the Compiler Platform Tools architecture
                            <arch>: x86 | amd64 | arm | x86_amd64 | x86_arm | amd64_x86 | amd64_arm
  /vcvars:store             Use Windows Store (rather than desktop) development tools
  /vcvars:sdk:<version>     Use a specific Windows SDK version:
                            <version> is either the full Windows 10 SDK version number or 
                            "8.1" to use the windows 8.1 SDK
"""

when isMainModule:
  var platformArg: string = nil
  var storeArg: bool = false
  var sdkVersionArg: string = nil
  var clArgs: seq[TaintedString] = @[]
  var wrapperArgs = commandLineParams()
  for wargv in wrapperArgs:
    # Check whether the current argument contains vcvars prefix
    if cmpIgnoreCase(wargv.substr(vcvarsArgIdx, argsToken1Idx - 1), vcvarsArgPrefix) == 0:
      # Check for platform
      if cmpIgnoreCase(wargv.substr(argsToken1Idx, platformArgValueIdx - 1), platformArgPrefix) == 0:
        platformArg = wargv.substr(platformArgValueIdx)
      # Check for store
      elif cmpIgnoreCase(wargv.substr(argsToken1Idx), storeArgPrefix) == 0:
        storeArg = true
      # Check for sdk
      elif cmpIgnoreCase(wargv.substr(argsToken1Idx, sdkArgValueIdx - 1), sdkArgPrefix) == 0:
        sdkVersionArg = wargv.substr(sdkArgValueIdx)
    else: # Regular cl.exe argument -> store for final cl.exe invocation
      if (wargv.len == 2) and (wargv[1] == '?'):
        echo HelpText
      clArgs.add(wargv)

  var vccEnvStrTab = getVccEnv(platformArg, storeArg, sdkVersionArg)  
  if vccEnvStrTab != nil:
    for vccEnvKey, vccEnvVal in vccEnvStrTab:
      putEnv(vccEnvKey, vccEnvVal)
  let vccProcess = startProcess(
      "link.exe",
      args = clArgs,
      options = vccOptions
    )
  quit vccProcess.waitForExit()
