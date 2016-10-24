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
    if existsEnv vsComnToolsEnvKey:
      let vsComnToolsEnvVal = getEnv vsComnToolsEnvKey
      if (not vsComnToolsEnvVal.isNil) and (vsComnToolsEnvVal.len > 0):
        return vsComnToolsEnvVal
  return nil    

proc getVccEnv*(platform: string, windowsStoreSdk: bool = false, sdkVersion: string = nil): StringTableRef =
  var comSpecCommandString: TaintedString
  if existsEnv comSpecEnvKey:
    comSpecCommandString = getEnv comSpecEnvKey
  else:
    comSpecCommandString = "cmd"
  
  let vsComnToolsPath = getVsComnToolsPath()
  if (isNil vsComnToolsPath) or (vsComnToolsPath.len < 1):
    return nil
  let vcvarsallPath = expandFilename joinPath(vsComnToolsPath, vcvarsallRelativePath)

  var vcvarsallArgs: seq[string] = @[]
  if (not isNil platform) and (platform.len > 0):
    vcvarsallArgs.add(platform)
  if windowsStoreSdk:
    vcvarsallArgs.add("store")
  if (not isNil sdkVersion) and (sdkVersion.len > 0):
    vcvarsallArgs.add(sdkVersion)
  var vcvarsallArgString: string
  if vcvarsallArgs.len > 0:
    vcvarsallArgString = vcvarsallArgs.join(" ")
  else:
    vcvarsallArgString = nil

  var vcvarsallCommandString: string
  if (not isNil vcvarsallArgString) and (vcvarsallArgString.len > 0):
    vcvarsallCommandString = "\"$1\" $2" % [ vcvarsallPath, vcvarsallArgString ]
  else:
    vcvarsallCommandString = vcvarsallPath

  let vcvarsallExecCommand = "\"$1\" /C \"$2 && SET\"" % [ comSpecCommandString, vcvarsallCommandString ]
  when defined(release):
    let vccvarsallOptions = { poEvalCommand, poDemon }
  else:
    let vccvarsallOptions = { poEchoCmd, poEvalCommand, poDemon }
  let vcvarsallStdOut = execProcess(vcvarsallExecCommand, options = vccvarsallOptions)
  let vcvarsallEnv = newStringTable(modeCaseInsensitive)   
  for vcvarsallEnvLine in vcvarsallStdOut.splitLines:
    let vcvarsallEqualsIndex = vcvarsallEnvLine.find('=')
    if vcvarsallEqualsIndex > 0:
      let vcvarsallEnvKey = vcvarsallEnvLine[0..(vcvarsallEqualsIndex - 1)]
      let vcvarsallEnvVal = vcvarsallEnvLine[(vcvarsallEqualsIndex + 1)..(vcvarsallEnvLine.len - 1)]
      vcvarsallEnv[vcvarsallEnvKey] = vcvarsallEnvVal
  return vcvarsallEnv
