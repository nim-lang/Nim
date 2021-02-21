import strutils, strtabs, os, osproc, vcvarsall, vccenv, vccvswhere

type
  VccVersion* = enum ## VCC compiler backend versions
    vccUndefined = 0,   ## VCC version undefined, resolves to the latest recognizable VCC version
    vcc90  = vs90  ## Visual Studio 2008 (Version 9.0)
    vcc100 = vs100 ## Visual Studio 2010 (Version 10.0)
    vcc110 = vs110 ## Visual Studio 2012 (Version 11.0)
    vcc120 = vs120 ## Visual Studio 2013 (Version 12.0)
    vcc140 = vs140 ## Visual Studio 2015 (Version 14.0)

proc discoverVccVcVarsAllPath*(version: VccVersion = vccUndefined): string =
  ## Returns the path to the vcvarsall utility of the specified VCC compiler backend.
  ##
  ## version
  ##   The specific version of the VCC compiler backend to discover.
  ##   Defaults to the latest recognized VCC compiler backend that is found on the system.
  ##
  ## Returns `nil` if the VCC compiler backend discovery failed.

  # Attempt discovery using vswhere utility (VS 2017 and later) if no version specified.
  if version == vccUndefined:
    result = vccVswhereVcVarsAllPath()
    if result.len > 0:
      return

  # Attempt discovery through VccEnv
  # (Trying Visual Studio Common Tools Environment Variables)
  result = vccEnvVcVarsAllPath(cast[VccEnvVersion](version))
  if result.len > 0:
    return

  # All attempts to discover vcc failed

const
  vccversionPrefix = "--vccversion"
  printPathPrefix = "--printPath"
  vcvarsallPrefix = "--vcvarsall"
  commandPrefix = "--command"
  noCommandPrefix = "--noCommand"
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

  vcvarsallDefaultPath = "vcvarsall.bat"

  helpText = """
+-----------------------------------------------------------------+
|         Microsoft C/C++ compiler wrapper for Nim                |
|                                &                                |
|        Microsoft C/C++ Compiler Discovery Utility               |
|            (c) 2017 Fredrik Hoeisaether Rasch                   |
+-----------------------------------------------------------------+

Usage:
  vccexe [options] [compileroptions]
Options:
  --vccversion:<v>    Optionally specify the VCC version to discover
                      <v>: 0, 90, 100, 110, 120, 140
                      If <v> is omitted, attempts to discover the latest
                      installed version. <v>: 0, 90, 100, 110, 120, 140
                      A value of 0 will discover the latest installed SDK
                      Multiple values can be specified, separated by ,
  --printPath         Print the discovered path of the vcvarsall utility
                      of the VCC version specified with the --vccversion argument.
                      For each specified version the utility prints a line with the
                      following format: <version>: <path>
  --noCommand         Flag to suppress VCC secondary command execution
                      Useful in conjunction with --vccversion and --printPath to
                      only perform VCC discovery, but without executing VCC tools
  --vcvarsall:<path>  Path to the Developer Command Prompt utility vcvarsall.bat that selects
                      the appropriate development settings.
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

proc parseVccexeCmdLine(argseq: seq[string],
    vccversionArg: var seq[string], printPathArg: var bool,
    vcvarsallArg: var string, commandArg: var string, noCommandArg: var bool,
    platformArg: var VccArch, sdkTypeArg: var VccPlatformType,
    sdkVersionArg: var string, verboseArg: var bool,
    clArgs: var seq[string]) =
  ## Cannot use usual command-line argument parser here
  ## Since vccexe command-line arguments are intermingled
  ## with the secondary command-line arguments which have
  ## a syntax that is not supported by the default nim
  ## argument parser.
  for wargv in argseq:
    # Check whether the current argument contains -- prefix
    if wargv.startsWith("@"): # Check for response file prefix
      let
        responsefilename = wargv.substr(1)
        responsefilehandle = open(responsefilename)
        responsecontent = responsefilehandle.readAll()
        responseargs = parseCmdLine(responsecontent)
      parseVccexeCmdLine(responseargs, vccversionArg, printPathArg,
        vcvarsallArg, commandArg, noCommandArg, platformArg, sdkTypeArg,
        sdkVersionArg, verboseArg, clArgs)
    elif wargv.startsWith(vccversionPrefix): # Check for vccversion
      vccversionArg.add(wargv.substr(vccversionSepIdx + 1))
    elif wargv.cmpIgnoreCase(printPathPrefix) == 0: # Check for printPath
      printPathArg = true
    elif wargv.startsWith(vcvarsallPrefix): # Check for vcvarsall
      vcvarsallArg = wargv.substr(vcvarsallSepIdx + 1)
    elif wargv.startsWith(commandPrefix): # Check for command
      commandArg = wargv.substr(commandSepIdx + 1)
    elif wargv.cmpIgnoreCase(noCommandPrefix) == 0: # Check for noCommand
      noCommandArg = true
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
        echo helpText
      clArgs.add(wargv)

when isMainModule:
  var vccversionArg: seq[string] = @[]
  var printPathArg: bool = false
  var vcvarsallArg: string
  var commandArg: string
  var noCommandArg: bool = false
  var platformArg: VccArch
  var sdkTypeArg: VccPlatformType
  var sdkVersionArg: string
  var verboseArg: bool = false

  var clArgs: seq[string] = @[]

  let wrapperArgs = commandLineParams()
  parseVccexeCmdLine(wrapperArgs, vccversionArg, printPathArg, vcvarsallArg,
    commandArg, noCommandArg, platformArg, sdkTypeArg, sdkVersionArg,
    verboseArg,
    clArgs)

  # Support for multiple specified versions. Attempt VCC discovery for each version
  # specified, first successful discovery wins
  var vccversionValue: VccVersion = vccUndefined
  for vccversionItem in vccversionArg:
    try:
      vccversionValue = cast[VccVersion](parseInt(vccversionItem))
    except ValueError:
      continue
    vcvarsallArg = discoverVccVcVarsAllPath(vccversionValue)
    if vcvarsallArg.len > 0:
      break
  # VCC version not specified, discover latest (call discover without args)
  if vcvarsallArg.len < 1 and vccversionArg.len < 1:
    vccversionValue = vccUndefined
    vcvarsallArg = discoverVccVcVarsAllPath()

  if vcvarsallArg == "":
    # Assume that default executable is in current directory or in PATH
    vcvarsallArg = findExe(vcvarsallDefaultPath)

  if printPathArg:
    var head = $vccversionValue
    if head.len < 1:
      head = "latest"
    echo "$1: $2" % [head, vcvarsallArg]

  # Call vcvarsall to get the appropriate VCC process environment
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

  if not noCommandArg:
    # Run VCC command with the VCC process environment
    try:
      let vccProcess = startProcess(
          commandArg,
          args = clArgs,
          options = vccOptions
        )
      quit vccProcess.waitForExit()
    except:
      if vcvarsallArg.len != 0:
        echo "Hint: using " & vcvarsallArg
      else:
        echo "Hint: vcvarsall.bat was not found"
      raise
