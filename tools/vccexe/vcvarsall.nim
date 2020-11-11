## VCC Developer Command Prompt Loader
## 
## In order for the VCC compiler backend to work properly, it requires numerous
## environment variables to be set properly for the desired architecture and compile target.
## For that purpose the VCC compiler ships with the vcvarsall utility which is an executable
## batch script that can be used to properly set up an Command Prompt environment.

import strtabs, strutils, os, osproc

const
  comSpecEnvKey = "ComSpec" ## Environment Variable that specifies the command-line application path in Windows
                            ## Usually set to cmd.exe

type
  VccArch* = enum ## The VCC compile target architectures
    vccarchUnspecified = "",
    vccarchX86 = "x86", ## VCC for compilation against the x86 architecture.
    vccarchAmd64 = "amd64", ## VCC for compilation against the amd64 architecture.
    vccarchX86Amd64 = "x86_amd64", ## VCC cross-compilation tools using x86 VCC for compilation against the amd64 architecture.
    vccarchX86Arm = "x86_arm", ## VCC cross-compilation tools using x86 VCC for compilation against the ARM architecture.
    vccarchX86Arm64 = "x86_arm64", ## VCC cross-compilation tools using x86 VCC for compilation against the ARM (64-bit) architecture.
    vccarchAmd64X86 = "amd64_x86", ## VCC cross-compilation tools using amd64 VCC for compilation against the x86 architecture.
    vccarchAmd64Arm = "amd64_arm", ## VCC cross-compilation tools using amd64 VCC for compilation against the ARM architecture.
    vccarchAmd64Arm64 = "amd64_arm64", ## VCC cross-compilation tools using amd64 VCC for compilation against the ARM (64-bit) architecture.
    vccarchX64 = "x64", ## VCC for compilation against the x64 architecture.
    vccarchX64X86 = "x64_x86", ## VCC cross-compilation tools using x64 VCC for compilation against the x86 architecture.
    vccarchX64Arm = "x64_arm", ## VCC cross-compilation tools using x64 VCC for compilation against the ARM architecture.
    vccarchX64Arm64 = "x64_arm64" ## VCC cross-compilation tools using x64 VCC for compilation against the ARM (64-bit) architecture.

  VccPlatformType* = enum ## The VCC platform type of the compile target
    vccplatEmpty = "", ## Default (i.e. Desktop) Platfor Type
    vccplatStore = "store", ## Windows Store Application
    vccplatUWP = "uwp", ## Universal Windows Platform (UWP) Application
    vccplatOneCore = "onecore" # Undocumented platform type in the Windows SDK, probably XBox One SDK platform type.

proc vccVarsAll*(path: string, arch: VccArch = vccarchUnspecified, platform_type: VccPlatformType = vccplatEmpty, sdk_version: string = "", verbose: bool = false): StringTableRef =
  ## Returns a string table containing the proper process environment to successfully execute VCC compile commands for the specified SDK version, CPU architecture and platform type.
  ##
  ## path
  ##   The path to the vcvarsall utility for VCC compiler backend.
  ## arch
  ##   The compile target CPU architecture. Starting with Visual Studio 2017, this value must be specified and must not be set to `vccarchUnspecified`.
  ## platform_type
  ##   The compile target Platform Type. Defaults to the Windows Desktop platform, i.e. a regular Windows executable binary.
  ## sdk_version
  ##   The Windows SDK version to use.
  ## verbose
  ##   Echo the command-line passed on to the system to load the VCC environment. Defaults to `false`.

  if path == "":
    return nil
  
  let vccvarsallpath = path
  var args: seq[string] = @[]
  
  let archStr: string = $arch
  if archStr.len > 0:
    args.add(archStr)
  
  let platStr: string = $platform_type
  if platStr.len > 0:
    args.add(platStr)

  if sdk_version.len > 0:
    args.add(sdk_version)

  let argStr = args.join " "
  
  var vcvarsExec: string
  if argStr.len > 0:
    vcvarsExec = "\"$1\" $2" % [vccvarsallpath, argStr]
  else:
    vcvarsExec = "\"$1\"" % vccvarsallpath

  var comSpecCmd = getenv comSpecEnvKey
  if comSpecCmd.len < 1:
    comSpecCmd = "cmd"
  
  # Run the Windows Command Prompt with the /C argument
  # Execute vcvarsall with its command-line arguments
  # and then execute the SET command to list all environment variables
  let comSpecExec = "\"$1\" /C \"$2 && SET\"" % [comSpecCmd, vcvarsExec]
  var comSpecOpts = {poEvalCommand, poDaemon, poStdErrToStdOut}
  if verbose:
    comSpecOpts.incl poEchoCmd
  let comSpecOut = execProcess(comSpecExec, options = comSpecOpts)

  result = newStringTable(modeCaseInsensitive)

  # Parse the output of the final SET command to construct a String Table
  # with the appropriate environment variables
  for line in comSpecOut.splitLines:
    let idx = line.find('=')
    if idx > 0:
      result[line[0..(idx - 1)]] = line[(idx + 1)..(line.len - 1)]
    elif verbose:
      echo line
