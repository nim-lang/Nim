#
#           Atlas Package Cloner
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implementation of the "Nim virtual environment" (`atlas env`) feature.

import std / [os, strscans, strutils]
import context, gitops

when defined(windows):
  const
    BatchFile = """
@echo off
set PATH="$1";%PATH%
"""
else:
  const
    ShellFile = "export PATH=$1:$$PATH\n"

const
  ActivationFile = when defined(windows): "activate.bat" else: "activate.sh"

proc infoAboutActivation(c: var AtlasContext; nimDest, nimVersion: string) =
  when defined(windows):
    info c, toName(nimDest), "RUN\nnim-" & nimVersion & "\\activate.bat"
  else:
    info c, toName(nimDest), "RUN\nsource nim-" & nimVersion & "/activate.sh"

proc setupNimEnv*(c: var AtlasContext; nimVersion: string) =
  template isDevel(nimVersion: string): bool = nimVersion == "devel"

  template exec(c: var AtlasContext; command: string) =
    let cmd = command # eval once
    if os.execShellCmd(cmd) != 0:
      error c, toName("nim-" & nimVersion), "failed: " & cmd
      return

  let nimDest = "nim-" & nimVersion
  if dirExists(c.workspace / nimDest):
    if not fileExists(c.workspace / nimDest / ActivationFile):
      info c, toName(nimDest), "already exists; remove or rename and try again"
    else:
      infoAboutActivation c, nimDest, nimVersion
    return

  var major, minor, patch: int
  if nimVersion != "devel":
    if not scanf(nimVersion, "$i.$i.$i", major, minor, patch):
      error c, toName("nim"), "cannot parse version requirement"
      return
  let csourcesVersion =
    if nimVersion.isDevel or (major == 1 and minor >= 9) or major >= 2:
      # already uses csources_v2
      "csources_v2"
    elif major == 0:
      "csources" # has some chance of working
    else:
      "csources_v1"
  withDir c, c.workspace:
    if not dirExists(csourcesVersion):
      exec c, "git clone https://github.com/nim-lang/" & csourcesVersion
    exec c, "git clone https://github.com/nim-lang/nim " & nimDest
  withDir c, c.workspace / csourcesVersion:
    when defined(windows):
      exec c, "build.bat"
    else:
      let makeExe = findExe("make")
      if makeExe.len == 0:
        exec c, "sh build.sh"
      else:
        exec c, "make"
  let nimExe0 = ".." / csourcesVersion / "bin" / "nim".addFileExt(ExeExt)
  withDir c, c.workspace / nimDest:
    let nimExe = "bin" / "nim".addFileExt(ExeExt)
    copyFileWithPermissions nimExe0, nimExe
    let dep = Dependency(name: toName(nimDest), commit: nimVersion, self: 0,
                         algo: c.defaultAlgo,
                         query: createQueryEq(if nimVersion.isDevel: Version"#head" else: Version(nimVersion)))
    if not nimVersion.isDevel:
      let commit = versionToCommit(c, dep)
      if commit.len == 0:
        error c, toName(nimDest), "cannot resolve version to a commit"
        return
      checkoutGitCommit(c, dep.name, commit)
    exec c, nimExe & " c --noNimblePath --skipUserCfg --skipParentCfg --hints:off koch"
    let kochExe = when defined(windows): "koch.exe" else: "./koch"
    exec c, kochExe & " boot -d:release --skipUserCfg --skipParentCfg --hints:off"
    exec c, kochExe & " tools --skipUserCfg --skipParentCfg --hints:off"
    # remove any old atlas binary that we now would end up using:
    if cmpPaths(getAppDir(), c.workspace / nimDest / "bin") != 0:
      removeFile "bin" / "atlas".addFileExt(ExeExt)
    # unless --keep is used delete the csources because it takes up about 2GB and
    # is not necessary afterwards:
    if Keep notin c.flags:
      removeDir c.workspace / csourcesVersion / "c_code"
    let pathEntry = (c.workspace / nimDest / "bin")
    when defined(windows):
      writeFile "activate.bat", BatchFile % pathEntry.replace('/', '\\')
    else:
      writeFile "activate.sh", ShellFile % pathEntry
    infoAboutActivation c, nimDest, nimVersion
