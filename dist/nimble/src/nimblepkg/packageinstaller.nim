# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.
import os, strutils

# Local imports
import cli, options

when defined(windows):
  import common

  # This is just for Win XP support.
  # TODO: Drop XP support?
  from winlean import WINBOOL, DWORD
  type
    OSVERSIONINFO* {.final, pure.} = object
      dwOSVersionInfoSize*: DWORD
      dwMajorVersion*: DWORD
      dwMinorVersion*: DWORD
      dwBuildNumber*: DWORD
      dwPlatformId*: DWORD
      szCSDVersion*: array[0..127, char]

  proc GetVersionExA*(VersionInformation: var OSVERSIONINFO): WINBOOL{.stdcall,
    dynlib: "kernel32", importc: "GetVersionExA".}

proc setupBinSymlink*(symlinkDest, symlinkFilename: string,
                      options: Options): seq[string] =
  result = @[]
  let
    symlinkDestRel = relativePath(symlinkDest, symlinkFilename.parentDir())
    currentPerms = getFilePermissions(symlinkDest)
  setFilePermissions(symlinkDest, currentPerms + {fpUserExec})
  when defined(unix):
    display("Creating", "symlink: $1 -> $2" %
            [symlinkDest, symlinkFilename], priority = MediumPriority)
    if fileExists(symlinkFilename):
      let msg = "Symlink already exists in $1. Replacing." % symlinkFilename
      display("Warning:", msg, Warning, HighPriority)
      removeFile(symlinkFilename)

    createSymlink(symlinkDestRel, symlinkFilename)
    result.add symlinkFilename.extractFilename
  elif defined(windows):
    # There is a bug on XP, described here:
    # http://stackoverflow.com/questions/2182568/batch-script-is-not-executed-if-chcp-was-called
    # But this workaround brakes code page on newer systems, so we need to detect OS version
    var osver = OSVERSIONINFO()
    osver.dwOSVersionInfoSize = cast[DWORD](sizeof(OSVERSIONINFO))
    if GetVersionExA(osver) == WINBOOL(0):
      raise nimbleError(
        "Can't detect OS version: GetVersionExA call failed")
    let fixChcp = osver.dwMajorVersion <= 5

    # Create cmd.exe/powershell stub.
    let dest = symlinkFilename.changeFileExt("cmd")
    display("Creating", "stub: $1 -> $2" % [symlinkDest, dest],
            priority = MediumPriority)
    var contents = "@"
    if options.config.chcp:
      if fixChcp:
        contents.add "chcp 65001 > nul && "
      else: contents.add "chcp 65001 > nul\n@"
    contents.add "\"%~dp0\\" & symlinkDestRel & "\" %*\n"
    writeFile(dest, contents)
    result.add dest.extractFilename
    # For bash on Windows (Cygwin/Git bash).
    let bashDest = dest.changeFileExt("")
    display("Creating", "Cygwin stub: $1 -> $2" %
            [symlinkDest, bashDest], priority = MediumPriority)
    writeFile(bashDest, "\"`dirname \"$0\"`\\" & symlinkDestRel & "\" \"$@\"\n")
    result.add bashDest.extractFilename
  else:
    {.error: "Sorry, your platform is not supported.".}
