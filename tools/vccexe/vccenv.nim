import os

type
  VccEnvVersion* = enum
    vsUndefined = (0, ""),
    vs90  = (90,   "VS90COMNTOOLS"), # Visual Studio 2008
    vs100 = (100, "VS100COMNTOOLS"), # Visual Studio 2010
    vs110 = (110, "VS110COMNTOOLS"), # Visual Studio 2012
    vs120 = (120, "VS120COMNTOOLS"), # Visual Studio 2013
    vs140 = (140, "VS140COMNTOOLS")  # Visual Studio 2015

const
  vcvarsallRelativePath = joinPath("..", "..", "VC", "vcvarsall")

proc vccEnvVcVarsAllPath*(version: VccEnvVersion = vsUndefined): string =
  if version == vsUndefined:
    for tryVersion in [vs140, vs120, vs110, vs100, vs90]:
      let tryPath = vccEnvVcVarsAllPath(tryVersion)
      if tryPath.len > 0:
        result = tryPath
  else: # Specific version requested
    let key = $version
    let val = getEnv key
    if val.len > 0:
      result = expandFilename(val & vcvarsallRelativePath)
