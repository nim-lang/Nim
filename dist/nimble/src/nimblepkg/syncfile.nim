# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

## This module implement operations on a special `sync` file which is being kept
## in the hidden special VCS directory. It is used to keep the revisions of the
## package's develop mode dependencies at the time when the last `lock` or
## `sync` operation had been performed. The file is used to determine whether a
## new `lock` or `sync` command or a VCS `merge` or `rebase` command is needed
## when there is a conflict between the data written in it and the data from the
## lock file and from the working copy.

import tables, json, os
import common, sha1hashes, paths, vcstools, packageinfotypes

type
  SyncFileData = Table[string, Sha1Hash]
    # Maps develop mode dependency name to the VCS revision it has in the time
    # of the last `lock` or `sync` operation or when it is added as a develop
    # mode dependency if there is no such operations after that moment.
  
  SyncFile = object
    path: Path
    data: SyncFileData

  SyncFileJsonKeys = enum
    ## Represents the keys for the `sync` file Json objects.
    lsfjkVersion = "version"
    lsfjkData    = "data"

const
  syncFileExt     = ".nimble.sync"
  syncFileVersion = 1

proc getPkgDir(pkgInfo: PackageInfo): string =
  pkgInfo.myPath.splitFile.dir

proc getSyncFilePath(pkgInfo: PackageInfo): Path =  
  ## Returns a path to the sync file for package `pkgInfo`.

  let (vcsType, vcsSpecialDirPath) =
    # Do not use `pkgInfo.getNimbleFileDir` in order to avoid circular
    # dependencies.
    getVcsTypeAndSpecialDirPath(pkgInfo.getPkgDir)

  if vcsType == vcsTypeNone:
    # The directory is not under version control, and we have not a place where
    # to hide the sync file.
    raise nimbleError(
      msg  = "Sync file require current working directory to be under some " &
             "supported type of version control.",
      hint = "Put package's working directory under version control.")

  return vcsSpecialDirPath / (pkgInfo.basicInfo.name & syncFileExt).Path

proc load(syncFile: ref SyncFile, path: Path) =
  ## Loads a sync file.

  syncFile.path = path
  if not path.fileExists:
    return

  {.warning[UnsafeDefault]: off.}
  {.warning[ProveInit]: off.}
  syncFile.data = parseFile(path)[$lsfjkData].to(SyncFileData)
  {.warning[ProveInit]: on.}
  {.warning[UnsafeDefault]: on.}

proc getSyncFile*(pkgInfo: PackageInfo): ref SyncFile =
  # Returns a reference to the sync file data of the current working directory
  # package `pkgInfo`.

  assert pkgInfo.getPkgDir == getCurrentDir():
         "The package `pkgInfo` must be the current working directory package."

  var syncFile {.global.}: ref SyncFile
  once:
    syncFile.new
    let path = getSyncFilePath(pkgInfo)
    syncFile.load(path)
  return syncFile

proc save*(syncFile: ref SyncFile) =
  ## Saves a sync file.

  let jsonNode = %{
    $lsfjkVersion: %syncFileVersion,
    $lsfjkData:    %syncFile.data,
    }

  writeFile(syncFile.path, jsonNode.pretty)

proc getDepVcsRevision*(syncFile: ref SyncFile, depName: string): Sha1Hash =
  ## Returns the revision written in the sync file for develop mode dependency
  ## `depName`.
  syncFile.data.getOrDefault(depName, notSetSha1Hash)

proc setDepVcsRevision*(syncFile: ref SyncFile, depName: string,
                        vcsRevision: Sha1Hash) =
  ## Sets the revision in the sync file for the develop mode dependency
  ## `depName` to be equal to `vcsRevision`.

  syncFile.data[depName] = vcsRevision

proc clear*(syncFile: ref SyncFile) =
  ## Clears all the data from the sync file.

  {.warning[UnsafeDefault]: off.}
  syncFile.data.clear
  {.warning[UnsafeDefault]: on.}
