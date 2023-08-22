# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

import sets, tables
import version, sha1hashes

type
  DownloadMethod* {.pure.} = enum
    git = "git", hg = "hg"

  Checksums* = object
    sha1*: Sha1Hash

  LockFileDep* = object
    version*: Version
    vcsRevision*: Sha1Hash
    url*: string
    downloadMethod*: DownloadMethod
    dependencies*: seq[string]
    checksums*: Checksums

  LockFileDeps* = OrderedTable[string, LockFileDep]

  AllLockFileDeps* = Table[string, LockFileDeps]
    ## Base deps is stored with empty string key ""
    ## Other tasks have task name as key

  PackageMetaData* = object
    url*: string
    downloadMethod*: DownloadMethod
    vcsRevision*: Sha1Hash
    files*: seq[string]
    binaries*: seq[string]
    specialVersions*: HashSet[Version]
      # Special versions are aliases with which a single package can be
      # referred. For example a package can be versions `0.1.0`, `#head` and
      # `#master` at the same time.

  PackageBasicInfo* = tuple
    name: string
    version: Version
    checksum: Sha1Hash

  PackageInfo* = object
    myPath*: string ## The path of this .nimble file
    isNimScript*: bool ## Determines if this pkg info was read from a nims file
    isMinimal*: bool
    isInstalled*: bool ## Determines if the pkg this info belongs to is installed
    nimbleTasks*: HashSet[string] ## All tasks defined in the Nimble file
    postHooks*: HashSet[string] ## Useful to know so that Nimble doesn't execHook unnecessarily
    preHooks*: HashSet[string]
    author*: string
    description*: string
    license*: string
    skipDirs*: seq[string]
    skipFiles*: seq[string]
    skipExt*: seq[string]
    installDirs*: seq[string]
    installFiles*: seq[string]
    installExt*: seq[string]
    requires*: seq[PkgTuple]
    taskRequires*: Table[string, seq[PkgTuple]]
    bin*: Table[string, string]
    binDir*: string
    srcDir*: string
    backend*: string
    foreignDeps*: seq[string]
    basicInfo*: PackageBasicInfo
    lockedDeps*: AllLockFileDeps
    metaData*: PackageMetaData
    isLink*: bool

  Package* = object ## Definition of package from packages.json.
    # Required fields in a package.
    name*: string
    url*: string # Download location.
    license*: string
    downloadMethod*: DownloadMethod
    description*: string
    tags*: seq[string] # Even if empty, always a valid non nil seq. \
    # From here on, optional fields set to the empty string if not available.
    version*: Version
    dvcsTag*: string
    web*: string # Info url for humans.
    alias*: string ## A name of another package, that this package aliases.

  PackageDependenciesInfo* = tuple[deps: HashSet[PackageInfo], pkg: PackageInfo]

const noTask* = "" # Means that noTask is being ran. Use this as key for base dependencies
