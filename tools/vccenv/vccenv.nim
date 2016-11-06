import strtabs, os, osproc, streams, strutils

const
  comSpecEnvKey = "ComSpec"
  vsComnToolsEnvKeys = [
    "VS140COMNTOOLS",
    "VS130COMNTOOLS",
    "VS120COMNTOOLS",
    "VS110COMNTOOLS",
    "VS100COMNTOOLS",
    "VS90COMNTOOLS"
  ]
  vcvarsallRelativePath = joinPath("..", "..", "VC", "vcvarsall")

proc getVsComnToolsPath*(): TaintedString =
  for vsComnToolsEnvKey in vsComnToolsEnvKeys:
    let vsComnToolsEnvVal = getEnv vsComnToolsEnvKey
    if vsComnToolsEnvVal.len > 0:
      return vsComnToolsEnvVal

proc getVccEnv*(platform: string, windowsStoreSdk: bool = false,
                sdkVersion: string = nil): StringTableRef =
  var comSpecCommandString = getEnv comSpecEnvKey
  if comSpecCommandString.len == 0:
    comSpecCommandString = "cmd"

  let vsComnToolsPath = getVsComnToolsPath()
  if vsComnToolsPath.len < 1:
    return nil
  let vcvarsallPath = expandFilename joinPath(vsComnToolsPath, vcvarsallRelativePath)

  var vcvarsallArgs: seq[string] = @[]
  if platform.len > 0:
    vcvarsallArgs.add(platform)
  if windowsStoreSdk:
    vcvarsallArgs.add("store")
  if sdkVersion.len > 0:
    vcvarsallArgs.add(sdkVersion)
  let vcvarsallArgString = vcvarsallArgs.join(" ")

  var vcvarsallCommandString: string
  if vcvarsallArgString.len > 0:
    vcvarsallCommandString = "\"$1\" $2" % [vcvarsallPath, vcvarsallArgString]
  else:
    vcvarsallCommandString = vcvarsallPath

  let vcvarsallExecCommand = "\"$1\" /C \"$2 && SET\"" %
                             [comSpecCommandString, vcvarsallCommandString]
  when defined(release):
    let vccvarsallOptions = {poEvalCommand, poDemon}
  else:
    let vccvarsallOptions = {poEchoCmd, poEvalCommand, poDemon}
  let vcvarsallStdOut = execProcess(vcvarsallExecCommand, options = vccvarsallOptions)
  result = newStringTable(modeCaseInsensitive)
  for line in vcvarsallStdOut.splitLines:
    let idx = line.find('=')
    if idx > 0:
      result[line[0..(idx - 1)]] = line[(idx + 1)..(line.len - 1)]
