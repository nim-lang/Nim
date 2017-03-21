import strtabs, strutils, os, osproc

const
  comSpecEnvKey = "ComSpec" # Environment Variable that specifies the command-line application path in Windows
                            # Usually set to cmd.exe
  vcvarsallDefaultPath = "vcvarsall.bat"

type
  VccArch* = enum
    vccarchUnspecified = "",
    vccarchX86 = "x86",
    vccarchAmd64 = "amd64",
    vccarchX86Amd64 = "x86_amd64",
    vccarchX86Arm = "x86_arm",
    vccarchX86Arm64 = "x86_arm64",
    vccarchAmd64X86 = "amd64_x86",
    vccarchAmd64Arm = "amd64_arm",
    vccarchAmd64Arm64 = "amd64_arm64",
    vccarchX64 = "x64",
    vccarchX64X86 = "x64_x86",
    vccarchX64Arm = "x64_arm",
    vccarchX64Arm64 = "x64_arm64"

  VccPlatformType* = enum
    vccplatEmpty = "",
    vccplatStore = "store",
    vccplatUWP = "uwp",
    vccplatOneCore = "onecore"

proc vccVarsAll*(path: string, arch: VccArch = vccarchUnspecified, platform_type: VccPlatformType = vccplatEmpty, sdk_version: string = nil): StringTableRef =
  var vccvarsallpath = path
  # Assume that default executable is in current directory or in PATH
  if path == nil or path.len < 1:
    vccvarsallpath = vcvarsallDefaultPath
  
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
  
  let comSpecExec = "\"$1\" /C \"$2 && SET\"" % [comSpecCmd, vcvarsExec]
  when defined(release):
    let comSpecOpts = {poEvalCommand, poDemon, poStdErrToStdOut}
  else:
    let comSpecOpts = {poEchoCmd, poEvalCommand, poDemon, poStdErrToStdOut}
  let comSpecOut = execProcess(comSpecExec, options = comSpecOpts)
  result = newStringTable(modeCaseInsensitive)
  for line in comSpecOut.splitLines:
    let idx = line.find('=')
    if idx > 0:
      result[line[0..(idx - 1)]] = line[(idx + 1)..(line.len - 1)]
    else:
      when not defined(release) or defined(debug):
        echo line
