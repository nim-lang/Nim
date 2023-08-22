# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

import tables, os, json
import version, sha1hashes, packageinfotypes

type
  LockFileJsonKeys* = enum
    lfjkVersion = "version"
    lfjkPackages = "packages"
    lfjkPkgVcsRevision = "vcsRevision"
    lfjkTasks = "tasks"

const
  lockFileVersion = 2

proc initLockFileDep*: LockFileDep =
  result = LockFileDep(
    version: notSetVersion,
    vcsRevision: notSetSha1Hash,
    checksums: Checksums(sha1: notSetSha1Hash))

const
  notSetLockFileDep* = initLockFileDep()

proc writeLockFile*(fileName: string, packages: AllLockFileDeps) =
  ## Saves lock file on the disk in topologically sorted order of the
  ## dependencies.

  let mainJsonNode = %{
      $lfjkVersion: %lockFileVersion,
      $lfjkPackages: %packages[noTask]
  }
  # Store task graph seperate
  mainJsonNode[$lfjkTasks] = newJObject()
  for task, deps in packages:
    if task != noTask:
      mainJsonNode[$lfjkTasks][task] = %deps

  var s = mainJsonNode.pretty
  s.add '\n'
  writeFile(fileName, s)

proc readLockFile*(filePath: string): AllLockFileDeps =
  {.warning[UnsafeDefault]: off.}
  {.warning[ProveInit]: off.}
  let data = parseFile(filePath)
  result[noTask] = data[$lfjkPackages].to(LockFileDeps)
  if $lfjkTasks in data:
    for task, deps in data[$lfjkTasks]:
      result[task] = deps.to(LockFileDeps)
  {.warning[ProveInit]: on.}
  {.warning[UnsafeDefault]: on.}

proc getLockedDependencies*(lockFile: string): AllLockFileDeps =
  if lockFile.fileExists:
    result = lockFile.readLockFile
