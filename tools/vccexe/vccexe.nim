import strutils, strtabs, os, osproc, vcvarsall, vccdiscover

const 
  vccversionPrefix = "--vccversion"
  vcvarsallPrefix = "--vcvarsall"
  commandPrefix = "--command"
  platformPrefix = "--platform"
  sdktypePrefix = "--sdktype"
  sdkversionPrefix = "--sdkversion"
  verbosePrefix = "--verbose"

  vccversionSepIdx = vccversionPrefix.len
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
  --vccversion:<v>    Optionally specify the VCC version to discover
                      <v>: 0, 90, 100, 110, 120, 140
                      Argument value is passed on to vccdiscover utility
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
  --verbose           Echoes the command line for loading the Developer Command Prompt
                      and the command line passed on to the secondary command.

Other command line arguments are passed on to the
secondary command specified by --command or to the
Microsoft (R) C/C++ Optimizing Compiler if no secondary
command was specified
"""

when isMainModule:
  var vccversionArg: seq[string] = @[]
  var vcvarsallArg: string = nil
  var commandArg: string = nil
  var platformArg: VccArch
  var sdkTypeArg: VccPlatformType
  var sdkVersionArg: string = nil
  var verboseArg: bool = false

  var clArgs: seq[TaintedString] = @[]

  # Cannot use usual command-line argument parser here
  # Since vccexe command-line arguments are intermingled
  # with the secondary command-line arguments which have
  # a syntax that is not supported by the default nim
  # argument parser.
  var wrapperArgs = commandLineParams()
  for wargv in wrapperArgs:
    # Check whether the current argument contains -- prefix
    if wargv.startsWith(vccversionPrefix): # Check for vccversion
      vccversionArg.add(wargv.substr(vccversionSepIdx + 1))
    elif wargv.startsWith(vcvarsallPrefix): # Check for vcvarsall
      vcvarsallArg = wargv.substr(vcvarsallSepIdx + 1)
    elif wargv.startsWith(commandPrefix): # Check for command
      commandArg = wargv.substr(commandSepIdx + 1)
    elif wargv.startsWith(platformPrefix): # Check for platform
      platformArg = parseEnum[VccArch](wargv.substr(platformSepIdx + 1))
    elif wargv.startsWith(sdktypePrefix): # Check for sdktype
      sdkTypeArg = parseEnum[VccPlatformType](wargv.substr(sdktypeSepIdx + 1))
    elif wargv.startsWith(sdkversionPrefix): # Check for sdkversion
      sdkVersionArg = wargv.substr(sdkversionSepIdx + 1)
    elif wargv.startsWith(verbosePrefix):
      verboseArg = true
    else: # Regular cl.exe argument -> store for final cl.exe invocation
      if (wargv.len == 2) and (wargv[1] == '?'):
        echo HelpText
      clArgs.add(wargv)

  # Support for multiple specified versions. Attempt VCC discovery for each version
  # specified, first successful discovery wins
  for vccversionItem in vccversionArg:
    var vccversionValue: VccVersion
    try:
      vccversionValue = cast[VccVersion](parseInt(vccversionItem))
    except ValueError:
      continue
    vcvarsallArg = discoverVccVcVarsAllPath(vccversionValue)
    if vcvarsallArg.len > 0:
      break
  # VCC version not specified, discover latest (call discover without args)
  if vcvarsallArg.len < 1 and vccversionArg.len < 1:
    vcvarsallArg = discoverVccVcVarsAllPath()

  # Call vcvarsall to get the appropiate VCC process environment
  var vcvars = vccVarsAll(vcvarsallArg, platformArg, sdkTypeArg, sdkVersionArg, verboseArg)
  if vcvars != nil:
    for vccEnvKey, vccEnvVal in vcvars:
      putEnv(vccEnvKey, vccEnvVal)

  var vccOptions = {poParentStreams}
  if verboseArg:
    vccOptions.incl poEchoCmd

  # Default to the cl.exe command if no secondary command was specified
  if commandArg.len < 1:
    commandArg = "cl.exe"

  # Run VCC command with the VCC process environment
  let vccProcess = startProcess(
      commandArg,
      args = clArgs,
      options = vccOptions
    )
  quit vccProcess.waitForExit()
