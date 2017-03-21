import strutils, strtabs, os, osproc, vcvarsall

when defined(release):
  let vccOptions = {poParentStreams}
else:
  let vccOptions = {poEchoCmd, poParentStreams}

const 
  vcvarsallPrefix = "--vcvarsall"
  commandPrefix = "--command"
  platformPrefix = "--platform"
  sdktypePrefix = "--sdktype"
  sdkversionPrefix = "--sdkversion"

  vcvarsallSepIdx = vcvarsallPrefix.len
  commandSepIdx = commandPrefix.len
  platformSepIdx = platformPrefix.len
  sdktypeSepIdx = sdktypePrefix.len
  sdkversionSepIdx = sdkversionPrefix.len
  
  HelpText = """
+-----------------------------------------------------------------+
|         Microsoft C/C++ compiler wrapper for Nim                |
|            (c) 2017 Fredrik Hoeisaether Rasch                   |
+-----------------------------------------------------------------+

Usage:
  vccexe [options] [compileroptions]
Options:
  --vcvarsall:<path>  Path to the Developer Command Prompt utility vcvarsall.bat that selects
                      the appropiate devlopment settings.
                      Usual path for Visual Studio 2015 and below:
                        %VSInstallDir%\VC\vcvarsall
                      Usual path for Visual Studio 2017 and above:
                        %VSInstallDir%\VC\Auxiliary\Build\vcvarsall
  --command:<exec>    Specify the command to run once the development environment is loaded.
                      <exec> can be any command-line argument. Any arguments not recognized by vccexe
                      are passed on as arguments to this command.
                      cl.exe is invoked by default if this argument is omitted.
  --platform:<arch>   Specify the Compiler Platform Tools architecture
                      <arch>: x86 | amd64 | arm | x86_amd64 | x86_arm | amd64_x86 | amd64_arm
                      Values with two architectures (like x86_amd64) specify the architecture
                      of the cross-platform compiler (e.g. x86) and the target it compiles to (e.g. amd64).
  --sdktype:<type>    Specify the SDK flavor to use. Defaults to the Desktop SDK.
                      <type>: {empty} | store | uwp | onecore
  --sdkversion:<v>    Use a specific Windows SDK version:
                      <v> is either the full Windows 10 SDK version number or 
                      "8.1" to use the windows 8.1 SDK

Other command line arguments are passed on to the
secondary command specified by --command or to the
Microsoft (R) C/C++ Optimizing Compiler if no secondary
command was specified
"""

when isMainModule:
  var vcvarsallArg: string = nil
  var commandArg: string = nil
  var platformArg: VccArch
  var sdkTypeArg: VccPlatformType
  var sdkVersionArg: string = nil

  var clArgs: seq[TaintedString] = @[]

  var wrapperArgs = commandLineParams()
  for wargv in wrapperArgs:
    # Check whether the current argument contains -- prefix
    if wargv.startsWith(vcvarsallPrefix): # Check for vcvarsall
      vcvarsallArg = wargv.substr(vcvarsallSepIdx + 1)
    elif wargv.startsWith(commandPrefix): # Check for command
      commandArg = wargv.substr(commandSepIdx + 1)
    elif wargv.startsWith(platformPrefix): # Check for platform
      platformArg = parseEnum[VccArch](wargv.substr(platformSepIdx + 1))
    elif wargv.startsWith(sdktypePrefix): # Check for sdktype
      sdkTypeArg = parseEnum[VccPlatformType](wargv.substr(sdktypeSepIdx + 1))
    elif wargv.startsWith(sdkversionPrefix): # Check for sdkversion
      sdkVersionArg = wargv.substr(sdkversionSepIdx + 1)
    else: # Regular cl.exe argument -> store for final cl.exe invocation
      if (wargv.len == 2) and (wargv[1] == '?'):
        echo HelpText
      clArgs.add(wargv)

  var vcvars = vccVarsAll(vcvarsallArg, platformArg, sdkTypeArg, sdkVersionArg)
  if vcvars != nil:
    for vccEnvKey, vccEnvVal in vcvars:
      putEnv(vccEnvKey, vccEnvVal)

  if commandArg.len < 1:
    commandArg = "cl.exe"
  let vccProcess = startProcess(
      commandArg,
      args = clArgs,
      options = vccOptions
    )
  quit vccProcess.waitForExit()
