## VCC compiler backend installation discovery using Visual Studio common tools
## environment variables.

import os

type
  VccEnvVersion* = enum ## The version of the Visual Studio C/C++ Developer Environment to load
                        ## Valid versions are Versions of Visual Studio that permanently set a COMNTOOLS
                        ## environment variable. That includes Visual Studio version up to and including
                        ## Visual Studio 2015
    vsUndefined = (0, ""), ## Version not specified, use latest recognized version on the system
    vs90  = (90,   "VS90COMNTOOLS"), ## Visual Studio 2008
    vs100 = (100, "VS100COMNTOOLS"), ## Visual Studio 2010
    vs110 = (110, "VS110COMNTOOLS"), ## Visual Studio 2012
    vs120 = (120, "VS120COMNTOOLS"), ## Visual Studio 2013
    vs140 = (140, "VS140COMNTOOLS")  ## Visual Studio 2015

const
  vcvarsallRelativePath = joinPath("..", "..", "VC", "vcvarsall.bat") ## Relative path from the COMNTOOLS path to the vcvarsall file.

proc vccEnvVcVarsAllPath*(version: VccEnvVersion = vsUndefined): string = 
  ## Returns the path to the VCC Developer Command Prompt executable for the specified VCC version.
  ##
  ## Returns `nil` if the specified VCC compiler backend installation was not found.
  ## 
  ## If the `version` parameter is omitted or set to `vsUndefined`, `vccEnvVcVarsAllPath` searches 
  ## for the latest recognizable version of the VCC tools it can find.
  ## 
  ## `vccEnvVcVarsAllPath` uses the COMNTOOLS environment variables to find the Developer Command Prompt
  ## executable path. The COMNTOOLS environment variable are permanently set when Visual Studio is installed.
  ## Each version of Visual Studio has its own COMNTOOLS environment variable. E.g.: Visual Studio 2015 sets
  ## The VS140COMNTOOLS environment variable.
  ##
  ## Note: Beginning with Visual Studio 2017, the installers no longer set environment variables to allow for
  ## multiple side-by-side installations of Visual Studio. Therefore, `vccEnvVcVarsAllPath` cannot be used
  ## to detect the VCC Developer Command Prompt executable path for Visual Studio 2017 and later.

  if version == vsUndefined:
    for tryVersion in [vs140, vs120, vs110, vs100, vs90]:
      let tryPath = vccEnvVcVarsAllPath(tryVersion)
      if tryPath.len > 0:
        return tryPath
  else: # Specific version requested
    let key = $version
    let val = getEnv key
    if val.len > 0:
      result = try: expandFilename(joinPath(val, vcvarsallRelativePath)) except OSError: ""
