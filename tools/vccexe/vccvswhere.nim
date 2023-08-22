## VCC compiler discovery using vswhere (https://github.com/Microsoft/vswhere)

import os, osproc, strformat, strutils

const
  vswhereRelativePath = joinPath("Microsoft Visual Studio", "Installer", "vswhere.exe")
  vswhereArgs = "-latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath"
  vcvarsRelativePath = joinPath("VC", "Auxiliary", "Build", "vcvarsall.bat")

proc vccVswhereExtractVcVarsAllPath(vswherePath: string): string =
  ## Returns the path to `vcvarsall.bat` if Visual Studio location was obtained by executing `vswhere.exe`.
  ##
  ## `vcvarsall.bat` is supposed to exist under {vsPath}\VC\Auxiliary\Build directory.
  ##
  ## Returns "" if no appropriate `vcvarsall.bat` file was found.

  # For more detail on vswhere arguments, refer to https://github.com/microsoft/vswhere/wiki/Find-VC
  let vsPath = execProcess(&"\"{vswherePath}\" {vswhereArgs}").strip()
  if vsPath.len > 0:
    let vcvarsallPath = joinPath(vsPath, vcvarsRelativePath)
    if fileExists(vcvarsallPath):
      return vcvarsallPath

proc vccVswhereGeneratePath(envName: string): string =
  ## Generate a path to vswhere.exe under "Program Files" or "Program Files (x86)" depending on envName.
  ##
  ## Returns "" if an environment variable specified by envName was not available.

  let val = getEnv(envName)
  if val.len > 0:
    result = try: expandFilename(joinPath(val, vswhereRelativePath)) except OSError: ""

proc vccVswhereVcVarsAllPath*(): string = 
  ## Returns the path to `vcvarsall.bat` for the latest Visual Studio (2017 and later).
  ##
  ## Returns "" if no recognizable Visual Studio installation was found.
  ## 
  ## Note: Beginning with Visual Studio 2017, the installers no longer set environment variables to allow for
  ## multiple side-by-side installations of Visual Studio. Therefore, `vccEnvVcVarsAllPath` cannot be used
  ## to detect the VCC Developer Command Prompt executable path for Visual Studio 2017 and later.

  for tryEnv in ["ProgramFiles(x86)", "ProgramFiles"]:
    let vswherePath = vccVswhereGeneratePath(tryEnv)
    if vswherePath.len > 0 and fileExists(vswherePath):
      let vcVarsAllPath = vccVswhereExtractVcVarsAllPath(vswherePath)
      if vcVarsAllPath.len > 0:
        return vcVarsAllPath
