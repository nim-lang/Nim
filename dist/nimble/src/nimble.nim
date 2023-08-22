# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

import system except TResult

import os, tables, strtabs, json, algorithm, sets, uri, sugar, sequtils, osproc,
       strformat

import std/options as std_opt

import strutils except toLower
from unicode import toLower

import nimblepkg/packageinfotypes, nimblepkg/packageinfo, nimblepkg/version,
       nimblepkg/tools, nimblepkg/download, nimblepkg/config, nimblepkg/common,
       nimblepkg/publish, nimblepkg/options, nimblepkg/packageparser,
       nimblepkg/cli, nimblepkg/packageinstaller, nimblepkg/reversedeps,
       nimblepkg/nimscriptexecutor, nimblepkg/init, nimblepkg/vcstools,
       nimblepkg/checksums, nimblepkg/topologicalsort, nimblepkg/lockfile,
       nimblepkg/nimscriptwrapper, nimblepkg/developfile, nimblepkg/paths,
       nimblepkg/nimbledatafile, nimblepkg/packagemetadatafile,
       nimblepkg/displaymessages, nimblepkg/sha1hashes, nimblepkg/syncfile,
       nimblepkg/deps

const
  nimblePathsFileName* = "nimble.paths"
  nimbleConfigFileName* = "config.nims"
  gitIgnoreFileName = ".gitignore"
  hgIgnoreFileName = ".hgignore"
  nimblePathsEnv = "__NIMBLE_PATHS"

proc refresh(options: Options) =
  ## Downloads the package list from the specified URL.
  ##
  ## If the download is not successful, an exception is raised.
  if options.offline:
    raise nimbleError("Cannot refresh package list in offline mode.")

  let parameter =
    if options.action.typ == actionRefresh:
      options.action.optionalURL
    else:
      ""

  if parameter.len > 0:
    if parameter.isUrl:
      let cmdLine = PackageList(name: "commandline", urls: @[parameter])
      fetchList(cmdLine, options)
    else:
      if parameter notin options.config.packageLists:
        let msg = "Package list with the specified name not found."
        raise nimbleError(msg)

      fetchList(options.config.packageLists[parameter], options)
  else:
    # Try each package list in config
    for name, list in options.config.packageLists:
      fetchList(list, options)

proc initPkgList(pkgInfo: PackageInfo, options: Options): seq[PackageInfo] =
  let
    installedPkgs = getInstalledPkgsMin(options.getPkgsDir(), options)
    developPkgs = processDevelopDependencies(pkgInfo, options)
  {.warning[ProveInit]: off.}
  result = concat(installedPkgs, developPkgs)
  {.warning[ProveInit]: on.}

proc install(packages: seq[PkgTuple], options: Options,
             doPrompt, first, fromLockFile: bool): PackageDependenciesInfo

proc checkSatisfied(options: Options, dependencies: HashSet[PackageInfo]) =
  ## Check if two packages of the same name (but different version) are listed
  ## in the path. Throws error if it fails
  var pkgsInPath: Table[string, Version]
  for pkgInfo in dependencies:
    let currentVer = pkgInfo.getConcreteVersion(options)
    if pkgsInPath.hasKey(pkgInfo.basicInfo.name) and
       pkgsInPath[pkgInfo.basicInfo.name] != currentVer:
      raise nimbleError(
        "Cannot satisfy the dependency on $1 $2 and $1 $3" %
          [pkgInfo.basicInfo.name, $currentVer, $pkgsInPath[pkgInfo.basicInfo.name]])
    pkgsInPath[pkgInfo.basicInfo.name] = currentVer

proc processFreeDependencies(pkgInfo: PackageInfo, requirements: seq[PkgTuple],
                             options: Options, nimAsDependency = false):
    HashSet[PackageInfo] =
  ## Verifies and installs dependencies.
  ##
  ## Returns set of PackageInfo (for paths) to pass to the compiler
  ## during build phase.
  assert not pkgInfo.isMinimal,
         "processFreeDependencies needs pkgInfo.requires"

  var pkgList {.global.}: seq[PackageInfo]
  once: pkgList = initPkgList(pkgInfo, options)
  display("Verifying", "dependencies for $1@$2" %
          [pkgInfo.basicInfo.name, $pkgInfo.basicInfo.version],
          priority = HighPriority)

  var reverseDependencies: seq[PackageBasicInfo] = @[]

  for dep in requirements:
    if not nimAsDependency and dep.name.isNim:
      let nimVer = getNimrodVersion(options)
      if not withinRange(nimVer, dep.ver):
        let msg = "Unsatisfied dependency: " & dep.name & " (" & $dep.ver & ")"
        raise nimbleError(msg)
    else:
      let resolvedDep = dep.resolveAlias(options)
      display("Checking", "for $1" % $resolvedDep, priority = MediumPriority)
      var pkg = initPackageInfo()
      var found = findPkg(pkgList, resolvedDep, pkg)
      # Check if the original name exists.
      if not found and resolvedDep.name != dep.name:
        display("Checking", "for $1" % $dep, priority = MediumPriority)
        found = findPkg(pkgList, dep, pkg)
        if found:
          displayWarning(&"Installed package {dep.name} should be renamed to " &
                         resolvedDep.name)

      if not found:
        display("Installing", $resolvedDep, priority = HighPriority)
        let toInstall = @[(resolvedDep.name, resolvedDep.ver)]
        let (packages, installedPkg) = install(toInstall, options,
          doPrompt = false, first = false, fromLockFile = false)

        for pkg in packages:
          if result.contains pkg:
            # If the result already contains the newly tried to install package
            # we had to merge its special versions set into the set of the old
            # one.
            result[pkg].metaData.specialVersions.incl(
              pkg.metaData.specialVersions)
          else:
            result.incl pkg

        pkg = installedPkg # For addRevDep
        fillMetaData(pkg, pkg.getRealDir(), false)

        # This package has been installed so we add it to our pkgList.
        pkgList.add pkg
      else:
        displayInfo(pkgDepsAlreadySatisfiedMsg(dep))
        result.incl pkg
        # Process the dependencies of this dependency.
        let fullInfo = pkg.toFullInfo(options)
        result.incl processFreeDependencies(fullInfo, fullInfo.requires, options)

      if not pkg.isLink:
        reverseDependencies.add(pkg.basicInfo)

  options.checkSatisfied(result)

  # We add the reverse deps to the JSON file here because we don't want
  # them added if the above errorenous condition occurs
  # (unsatisfiable dependendencies).
  # N.B. NimbleData is saved in installFromDir.
  for i in reverseDependencies:
    addRevDep(options.nimbleData, i, pkgInfo)

proc buildFromDir(pkgInfo: PackageInfo, paths: HashSet[string],
                  args: seq[string], options: Options) =
  ## Builds a package as specified by ``pkgInfo``.
  # Handle pre-`build` hook.
  let
    realDir = pkgInfo.getRealDir()
    pkgDir = pkgInfo.myPath.parentDir()

  cd pkgDir: # Make sure `execHook` executes the correct .nimble file.
    if not execHook(options, actionBuild, true):
      raise nimbleError("Pre-hook prevented further execution.")

  if pkgInfo.bin.len == 0:
    raise nimbleError(
        "Nothing to build. Did you specify a module to build using the" &
        " `bin` key in your .nimble file?")

  var
    binariesBuilt = 0
    args = args
  args.add "-d:NimblePkgVersion=" & $pkgInfo.basicInfo.version
  for path in paths:
    args.add("--path:" & path.quoteShell)
  if options.verbosity >= HighPriority:
    # Hide Nim hints by default
    args.add("--hints:off")
  if options.verbosity == SilentPriority:
    # Hide Nim warnings
    args.add("--warnings:off")

  let binToBuild =
    # Only build binaries specified by user if any, but only if top-level package,
    # dependencies should have every binary built.
    if options.isInstallingTopLevel(pkgInfo.myPath.parentDir()):
      options.getCompilationBinary(pkgInfo).get("")
    else: ""

  for bin, src in pkgInfo.bin:
    # Check if this is the only binary that we want to build.
    if binToBuild.len != 0 and binToBuild != bin:
      if bin.extractFilename().changeFileExt("") != binToBuild:
        continue

    let outputDir = pkgInfo.getOutputDir("")
    if dirExists(outputDir):
      if fileExists(outputDir / bin):
        if not pkgInfo.needsRebuild(outputDir / bin, realDir, options):
          display("Skipping", "$1/$2 (up-to-date)" %
                  [pkginfo.basicInfo.name, bin], priority = HighPriority)
          binariesBuilt.inc()
          continue
    else:
      createDir(outputDir)

    let outputOpt = "-o:" & pkgInfo.getOutputDir(bin).quoteShell
    display("Building", "$1/$2 using $3 backend" %
            [pkginfo.basicInfo.name, bin, pkgInfo.backend], priority = HighPriority)

    let input = realDir / src.changeFileExt("nim")
    # `quoteShell` would be more robust than `\"` (and avoid quoting when
    # un-necessary) but would require changing `extractBin`
    let cmd = "$# $# --colors:on --noNimblePath $# $# $#" % [
      pkgInfo.getNimBin(options).quoteShell, pkgInfo.backend, join(args, " "),
      outputOpt, input.quoteShell]
    try:
      doCmd(cmd)
      binariesBuilt.inc()
    except CatchableError as error:
      raise buildFailed(
        &"Build failed for the package: {pkgInfo.basicInfo.name}", details = error)

  if binariesBuilt == 0:
    raise nimbleError(
      "No binaries built, did you specify a valid binary name?"
    )

  # Handle post-`build` hook.
  cd pkgDir: # Make sure `execHook` executes the correct .nimble file.
    discard execHook(options, actionBuild, false)

proc cleanFromDir(pkgInfo: PackageInfo, options: Options) =
  ## Clean up build files.
  # Handle pre-`clean` hook.
  let pkgDir = pkgInfo.myPath.parentDir()

  cd pkgDir: # Make sure `execHook` executes the correct .nimble file.
    if not execHook(options, actionClean, true):
      raise nimbleError("Pre-hook prevented further execution.")

  if pkgInfo.bin.len == 0:
    return

  for bin, _ in pkgInfo.bin:
    let outputDir = pkgInfo.getOutputDir("")
    if dirExists(outputDir):
      if fileExists(outputDir / bin):
        removeFile(outputDir / bin)

  # Handle post-`clean` hook.
  cd pkgDir: # Make sure `execHook` executes the correct .nimble file.
    discard execHook(options, actionClean, false)

proc promptRemoveEntirePackageDir(pkgDir: string, options: Options) =
  let exceptionMsg = getCurrentExceptionMsg()
  let warningMsgEnd = if exceptionMsg.len > 0: &": {exceptionMsg}" else: "."
  let warningMsg = &"Unable to read {packageMetaDataFileName}{warningMsgEnd}"

  display("Warning", warningMsg, Warning, HighPriority)

  if not options.prompt(
      &"Would you like to COMPLETELY remove ALL files in {pkgDir}?"):
    raise nimbleQuit()

proc removePackageDir(pkgInfo: PackageInfo, pkgDestDir: string) =
  removePackageDir(pkgInfo.metaData.files & packageMetaDataFileName, pkgDestDir)

proc removeBinariesSymlinks(pkgInfo: PackageInfo, binDir: string) =
  for bin in pkgInfo.metaData.binaries:
    when defined(windows):
      removeFile(binDir / bin.changeFileExt("cmd"))
    removeFile(binDir / bin)

proc reinstallSymlinksForOlderVersion(pkgDir: string, options: Options) =
  let (pkgName, _, _) = getNameVersionChecksum(pkgDir)
  let pkgList = getInstalledPkgsMin(options.getPkgsDir(), options)
  var newPkgInfo = initPackageInfo()
  if pkgList.findPkg((pkgName, newVRAny()), newPkgInfo):
    newPkgInfo = newPkgInfo.toFullInfo(options)
    for bin, _ in newPkgInfo.bin:
      let symlinkDest = newPkgInfo.getOutputDir(bin)
      let symlinkFilename = options.getBinDir() / bin.extractFilename
      discard setupBinSymlink(symlinkDest, symlinkFilename, options)

proc removePackage(pkgInfo: PackageInfo, options: Options) =
  var pkgInfo = pkgInfo
  let pkgDestDir = pkgInfo.getPkgDest(options)

  if not pkgInfo.hasMetaData:
    try:
      fillMetaData(pkgInfo, pkgDestDir, true)
    except MetaDataError, ValueError:
      promptRemoveEntirePackageDir(pkgDestDir, options)
      removeDir(pkgDestDir)

  removePackageDir(pkgInfo, pkgDestDir)
  removeBinariesSymlinks(pkgInfo, options.getBinDir())
  reinstallSymlinksForOlderVersion(pkgDestDir, options)
  options.nimbleData.removeRevDep(pkgInfo)

proc packageExists(pkgInfo: PackageInfo, options: Options):
    Option[PackageInfo] =
  ## Checks whether a package `pkgInfo` already exists in the Nimble cache. If a
  ## package already exists returns the `PackageInfo` of the package in the
  ## cache otherwise returns `none`. Raises a `NimbleError` in the case the
  ## package exists in the cache but it is not valid.
  let pkgDestDir = pkgInfo.getPkgDest(options)
  if not fileExists(pkgDestDir / packageMetaDataFileName):
    return none[PackageInfo]()
  else:
    var oldPkgInfo = initPackageInfo()
    try:
      oldPkgInfo = pkgDestDir.getPkgInfo(options)
    except CatchableError as error:
      raise nimbleError(&"The package inside \"{pkgDestDir}\" is invalid.",
                        details = error)
    fillMetaData(oldPkgInfo, pkgDestDir, true)
    return some(oldPkgInfo)

proc processLockedDependencies(pkgInfo: PackageInfo, options: Options, onlyNim = false):
  HashSet[PackageInfo]

proc getDependenciesPaths(pkgInfo: PackageInfo, options: Options):
    HashSet[string]

proc processAllDependencies(pkgInfo: PackageInfo, options: Options):
    HashSet[PackageInfo] =
  if pkgInfo.hasLockedDeps():
    result = pkgInfo.processLockedDependencies(options)
  else:
    result.incl pkgInfo.processFreeDependencies(pkgInfo.requires, options)
    if options.task in pkgInfo.taskRequires:
      result.incl pkgInfo.processFreeDependencies(pkgInfo.taskRequires[options.task], options)

  putEnv(nimblePathsEnv, result.map(dep => dep.getRealDir()).toSeq().join("|"))

proc allDependencies(pkgInfo: PackageInfo, options: Options): HashSet[PackageInfo] =
  ## Returns all dependencies for a package (Including tasks)
  result.incl pkgInfo.processFreeDependencies(pkgInfo.requires, options)
  for requires in pkgInfo.taskRequires.values:
    result.incl pkgInfo.processFreeDependencies(requires, options)

proc installFromDir(dir: string, requestedVer: VersionRange, options: Options,
                    url: string, first: bool, fromLockFile: bool,
                    vcsRevision = notSetSha1Hash,
                    deps: seq[PackageInfo] = @[]):
    PackageDependenciesInfo =
  ## Returns where package has been installed to, together with paths
  ## to the packages this package depends on.
  ##
  ## The return value of this function is used by
  ## ``processFreeDependencies``
  ##   To gather a list of paths to pass to the Nim compiler.
  ##
  ## ``first``
  ##   True if this is the first level of the indirect recursion.
  ## ``fromLockFile``
  ##   True if we are installing dependencies from the lock file.

  # Handle pre-`install` hook.
  if not options.depsOnly:
    cd dir: # Make sure `execHook` executes the correct .nimble file.
      if not execHook(options, actionInstall, true):
        raise nimbleError("Pre-hook prevented further execution.")

  var pkgInfo = getPkgInfo(dir, options)
  # Set the flag that the package is not in develop mode before saving it to the
  # reverse dependencies.
  pkgInfo.isLink = false
  if vcsRevision != notSetSha1Hash:
    ## In the case we downloaded the package as tarball we have to set the VCS
    ## revision returned by download procedure because it cannot be queried from
    ## the package directory.
    pkgInfo.metaData.vcsRevision = vcsRevision

  let realDir = pkgInfo.getRealDir()
  let binDir = options.getBinDir()
  var depsOptions = options
  depsOptions.depsOnly = false

  if requestedVer.kind == verSpecial:
    # Add a version alias to special versions set if requested version is a
    # special one.
    pkgInfo.metaData.specialVersions.incl requestedVer.spe

  # Dependencies need to be processed before the creation of the pkg dir.
  if first and pkgInfo.hasLockedDeps():
    result.deps = pkgInfo.processLockedDependencies(depsOptions)
  elif not fromLockFile:
    result.deps = pkgInfo.processFreeDependencies(pkgInfo.requires, depsOptions)
  else:
    result.deps = deps.toHashSet

  if options.depsOnly:
    result.pkg = pkgInfo
    return result

  display("Installing", "$1@$2" %
    [pkginfo.basicInfo.name, $pkginfo.basicInfo.version],
    priority = HighPriority)

  let oldPkg = pkgInfo.packageExists(options)
  if oldPkg.isSome:
    # In the case we already have the same package in the cache then only merge
    # the new package special versions to the old one.
    displayWarning(pkgAlreadyExistsInTheCacheMsg(pkgInfo))
    var oldPkg = oldPkg.get
    oldPkg.metaData.specialVersions.incl pkgInfo.metaData.specialVersions
    saveMetaData(oldPkg.metaData, oldPkg.getNimbleFileDir, changeRoots = false)
    if result.deps.contains oldPkg:
      result.deps[oldPkg].metaData.specialVersions.incl(
        oldPkg.metaData.specialVersions)
    result.deps.incl oldPkg
    result.pkg = oldPkg
    return

  # nim is intended only for local project local usage, so avoid installing it
  # in .nimble/bin
  let isNimPackage = pkgInfo.basicInfo.name.isNim

  # Build before removing an existing package (if one exists). This way
  # if the build fails then the old package will still be installed.

  if pkgInfo.bin.len > 0 and not isNimPackage:
    let paths = result.deps.map(dep => dep.getRealDir())
    let flags = if options.action.typ in {actionInstall, actionPath, actionUninstall, actionDevelop}:
                  options.action.passNimFlags
                else:
                  @[]

    try:
      buildFromDir(pkgInfo, paths, "-d:release" & flags, options)
    except CatchableError:
      removeRevDep(options.nimbleData, pkgInfo)
      raise

  let pkgDestDir = pkgInfo.getPkgDest(options)

  # Fill package Meta data
  pkgInfo.metaData.url = url
  pkgInfo.isLink = false

  # Don't copy artifacts if project local deps mode and "installing" the top
  # level package.
  if not (options.localdeps and options.isInstallingTopLevel(dir)):
    createDir(pkgDestDir)
    # Copy this package's files based on the preferences specified in PkgInfo.
    var filesInstalled: HashSet[string]
    iterInstallFiles(realDir, pkgInfo, options,
      proc (file: string) =
        createDir(changeRoot(realDir, pkgDestDir, file.splitFile.dir))
        let dest = changeRoot(realDir, pkgDestDir, file)
        filesInstalled.incl copyFileD(file, dest)
    )

    # Copy the .nimble file.
    let dest = changeRoot(pkgInfo.myPath.splitFile.dir, pkgDestDir,
                          pkgInfo.myPath)
    filesInstalled.incl copyFileD(pkgInfo.myPath, dest)

    var binariesInstalled: HashSet[string]
    if pkgInfo.bin.len > 0 and not pkgInfo.basicInfo.name.isNim:
      # Make sure ~/.nimble/bin directory is created.
      createDir(binDir)
      # Set file permissions to +x for all binaries built,
      # and symlink them on *nix OS' to $nimbleDir/bin/
      for bin, src in pkgInfo.bin:
        let binDest =
          # Issue #308
          if dirExists(pkgDestDir / bin):
            bin & ".out"
          else: bin

        if fileExists(pkgDestDir / binDest):
          display("Warning:", ("Binary '$1' was already installed from source" &
                              " directory. Will be overwritten.") % bin, Warning,
                  MediumPriority)

        # Copy the binary file.
        createDir((pkgDestDir / binDest).parentDir())
        filesInstalled.incl copyFileD(pkgInfo.getOutputDir(bin),
                                      pkgDestDir / binDest)

        # Set up a symlink.
        let symlinkDest = pkgDestDir / binDest
        let symlinkFilename = options.getBinDir() / bin.extractFilename
        binariesInstalled.incl(
          setupBinSymlink(symlinkDest, symlinkFilename, options))

    # Update package path to point to installed directory rather than the temp
    # directory.
    pkgInfo.myPath = dest
    pkgInfo.metaData.files = filesInstalled.toSeq
    pkgInfo.metaData.binaries = binariesInstalled.toSeq

    saveMetaData(pkgInfo.metaData, pkgDestDir)
  else:
    display("Warning:", "Skipped copy in project local deps mode", Warning)

  pkgInfo.isInstalled = true

  displaySuccess(pkgInstalledMsg(pkgInfo.basicInfo.name))

  result.deps.incl pkgInfo
  result.pkg = pkgInfo

  # Run post-install hook now that package is installed. The `execHook` proc
  # executes the hook defined in the CWD, so we set it to where the package
  # has been installed.
  cd pkgInfo.myPath.splitFile.dir:
    discard execHook(options, actionInstall, false)

proc getDependencyDir(name: string, dep: LockFileDep, options: Options):
    string =
  ## Returns the installation directory for a dependency from the lock file.
  options.getPkgsDir() /  &"{name}-{dep.version}-{dep.checksums.sha1}"

proc isInstalled(name: string, dep: LockFileDep, options: Options): bool =
  ## Checks whether a dependency from the lock file is already installed.
  fileExists(getDependencyDir(name, dep, options) / packageMetaDataFileName)

proc getDependency(name: string, dep: LockFileDep, options: Options):
    PackageInfo =
  ## Returns a `PackageInfo` for an already installed dependency from the
  ## lock file.
  let depDirName = getDependencyDir(name, dep, options)
  let nimbleFilePath = findNimbleFile(depDirName, false)
  getInstalledPackageMin(options, depDirName, nimbleFilePath).toFullInfo(options)

type
  DownloadInfo = ref object
    ## Information for a downloaded dependency needed for installation.
    name: string
    dependency: LockFileDep
    url: string
    version: VersionRange
    downloadDir: string
    vcsRevision: Sha1Hash

proc developWithDependencies(options: Options): bool =
  ## Determines whether the current executed action is a develop sub-command
  ## with `--with-dependencies` flag.
  options.action.typ == actionDevelop and options.action.withDependencies

proc raiseCannotCloneInExistingDirException(downloadDir: string) =
  let msg = "Cannot clone into '$1': directory exists." % downloadDir
  const hint = "Remove the directory, or run this command somewhere else."
  raise nimbleError(msg, hint)

proc downloadDependency(name: string, dep: LockFileDep, options: Options, validateRange = true):
    DownloadInfo =
  ## Downloads a dependency from the lock file.
  if options.offline:
    raise nimbleError("Cannot download in offline mode.")

  if not options.developWithDependencies:
    let depDirName = getDependencyDir(name, dep, options)
    if depDirName.dirExists:
      promptRemoveEntirePackageDir(depDirName, options)
      removeDir(depDirName)

  let (url, metadata) = getUrlData(dep.url)
  let version =  dep.version.parseVersionRange
  let subdir = metadata.getOrDefault("subdir")
  let downloadPath = if options.developWithDependencies:
    getDevelopDownloadDir(url, subdir, options) else: ""

  if dirExists(downloadPath):
    if options.developWithDependencies:
      displayWarning(skipDownloadingInAlreadyExistingDirectoryMsg(
        downloadPath, name))
      result = DownloadInfo(
        name: name,
        dependency: dep,
        url: url,
        version: version,
        downloadDir: downloadPath,
        vcsRevision: dep.vcsRevision)
      return
    else:
      raiseCannotCloneInExistingDirException(downloadPath)

  let (downloadDir, _, vcsRevision) = downloadPkg(
    url, version, dep.downloadMethod, subdir, options, downloadPath,
    dep.vcsRevision, validateRange = validateRange)

  let downloadedPackageChecksum = calculateDirSha1Checksum(downloadDir)
  if downloadedPackageChecksum != dep.checksums.sha1:
    raise checksumError(name, dep.version, dep.vcsRevision,
                        downloadedPackageChecksum, dep.checksums.sha1)

  result = DownloadInfo(
    name: name,
    dependency: dep,
    url: url,
    version: version,
    downloadDir: downloadDir,
    vcsRevision: vcsRevision)

proc installDependency(lockedDeps: Table[string, LockFileDep], downloadInfo: DownloadInfo,
                       options: Options,
                       deps: seq[PackageInfo]): PackageInfo =
  ## Installs an already downloaded dependency of the package `pkgInfo`.
  let (_, newlyInstalledPkgInfo) = installFromDir(
    downloadInfo.downloadDir,
    downloadInfo.version,
    options,
    downloadInfo.url,
    first = false,
    fromLockFile = true,
    downloadInfo.vcsRevision,
    deps = deps)

  downloadInfo.downloadDir.removeDir
  for depDepName in downloadInfo.dependency.dependencies:
    let depDep = lockedDeps[depDepName]
    let revDep = (name: depDepName, version: depDep.version,
                  checksum: depDep.checksums.sha1)
    options.nimbleData.addRevDep(revDep, newlyInstalledPkgInfo)

  return newlyInstalledPkgInfo

proc processLockedDependencies(pkgInfo: PackageInfo, options: Options, onlyNim = false):
    HashSet[PackageInfo] =
  # Returns a hash set with `PackageInfo` of all packages from the lock file of
  # the package `pkgInfo` by getting the info for develop mode dependencies from
  # their local file system directories and other packages from the Nimble
  # cache. If a package with required checksum is missing from the local cache
  # installs it by downloading it from its repository.

  let developModeDeps = getDevelopDependencies(pkgInfo, options)

  for name, dep in pkgInfo.lockedDeps.lockedDepsFor(options):
    if onlyNim and not name.isNim:
      continue
    if developModeDeps.hasKey(name):
      result.incl developModeDeps[name][]
    elif isInstalled(name, dep, options):
      result.incl getDependency(name, dep, options)
    elif not options.offline:
      let
        downloadResult = downloadDependency(name, dep, options)
        dependencies = result.toSeq.filterIt(dep.dependencies.contains(it.name))
      result.incl installDependency(pkgInfo.lockedDeps.lockedDepsFor(options).toSeq.toTable,
                                    downloadResult, options, dependencies)
    else:
      raise nimbleError("Unsatisfied dependency: " & pkgInfo.basicInfo.name)

proc getDownloadInfo*(pv: PkgTuple, options: Options,
                      doPrompt: bool, ignorePackageCache = false): (DownloadMethod, string,
                                        Table[string, string]) =
  if pv.name.isURL:
    let (url, metadata) = getUrlData(pv.name)
    return (checkUrlType(url), url, metadata)
  else:
    var pkg = initPackage()
    if getPackage(pv.name, options, pkg, ignorePackageCache):
      let (url, metadata) = getUrlData(pkg.url)
      return (pkg.downloadMethod, url, metadata)
    else:
      # If package is not found give the user a chance to refresh
      # package.json
      if doPrompt and not options.offline and
          options.prompt(pv.name & " not found in any local packages.json, " &
                         "check internet for updated packages?"):
        refresh(options)

        # Once we've refreshed, try again, but don't prompt if not found
        # (as we've already refreshed and a failure means it really
        # isn't there)
        # Also ignore the package cache so the old info isn't used
        return getDownloadInfo(pv, options, false, true)
      else:
        raise nimbleError(pkgNotFoundMsg(pv))

proc install(packages: seq[PkgTuple], options: Options,
             doPrompt, first, fromLockFile: bool): PackageDependenciesInfo =
  ## ``first``
  ##   True if this is the first level of the indirect recursion.
  ## ``fromLockFile``
  ##   True if we are installing dependencies from the lock file.

  if packages == @[]:
    let currentDir = getCurrentDir()
    if currentDir.developFileExists:
      displayWarning(
        "Installing a package which currently has develop mode dependencies." &
        "\nThey will be ignored and installed as normal packages.")
    result = installFromDir(currentDir, newVRAny(), options, "", first,
                            fromLockFile)
  else:
    # Install each package.
    for pv in packages:
      let (meth, url, metadata) = getDownloadInfo(pv, options, doPrompt)
      let subdir = metadata.getOrDefault("subdir")
      let (downloadDir, downloadVersion, vcsRevision) =
        downloadPkg(url, pv.ver, meth, subdir, options,
                    downloadPath = "", vcsRevision = notSetSha1Hash)
      try:
        result = installFromDir(downloadDir, pv.ver, options, url,
                                first, fromLockFile, vcsRevision)
      except BuildFailed as error:
        # The package failed to build.
        # Check if we tried building a tagged version of the package.
        let headVer = getHeadName(meth)
        if pv.ver.kind != verSpecial and downloadVersion != headVer and
           not fromLockFile:
          # If we tried building a tagged version of the package and this is not
          # fixed in the lock file version then ask the user whether they want
          # to try building #head.
          let promptResult = doPrompt and
              options.prompt(("Build failed for '$1@$2', would you" &
                  " like to try installing '$1@#head' (latest unstable)?") %
                  [pv.name, $downloadVersion])
          if promptResult:
            let toInstall = @[(pv.name, headVer.toVersionRange())]
            result =  install(toInstall, options, doPrompt, first,
                              fromLockFile = false)
          else:
            raise buildFailed(
              "Aborting installation due to build failure.", details = error)
        else:
          raise

proc getDependenciesPaths(pkgInfo: PackageInfo, options: Options):
    HashSet[string] =
  let deps = pkgInfo.processAllDependencies(options)
  return deps.map(dep => dep.getRealDir())

proc build(pkgInfo: PackageInfo, options: Options) =
  ## Builds the package `pkgInfo`.
  nimScriptHint(pkgInfo)
  let paths = pkgInfo.getDependenciesPaths(options)
  var args = options.getCompilationFlags()
  buildFromDir(pkgInfo, paths, args, options)

proc build(options: var Options) =
  getPkgInfo(getCurrentDir(), options).build(options)

proc clean(options: Options) =
  let dir = getCurrentDir()
  let pkgInfo = getPkgInfo(dir, options)
  nimScriptHint(pkgInfo)
  cleanFromDir(pkgInfo, options)

proc execBackend(pkgInfo: PackageInfo, options: Options) =
  let
    bin = options.getCompilationBinary(pkgInfo).get("")
    binDotNim = bin.addFileExt("nim")

  if bin == "":
    raise nimbleError("You need to specify a file.")

  if not (fileExists(bin) or fileExists(binDotNim)):
    raise nimbleError(
      "Specified file, " & bin & " or " & binDotNim & ", does not exist.")

  let pkgInfo = getPkgInfo(getCurrentDir(), options)
  nimScriptHint(pkgInfo)

  let deps = pkgInfo.processAllDependencies(options)
  if not execHook(options, options.action.typ, true):
    raise nimbleError("Pre-hook prevented further execution.")

  var args = @["-d:NimblePkgVersion=" & $pkgInfo.basicInfo.version]
  for dep in deps:
    args.add("--path:" & dep.getRealDir().quoteShell)
  if options.verbosity >= HighPriority:
    # Hide Nim hints by default
    args.add("--hints:off")
  if options.verbosity == SilentPriority:
    # Hide Nim warnings
    args.add("--warnings:off")

  for option in options.getCompilationFlags():
    args.add(option.quoteShell)

  let backend =
    if options.action.backend.len > 0:
      options.action.backend
    else:
      pkgInfo.backend

  if options.action.typ == actionCompile:
    display("Compiling", "$1 (from package $2) using $3 backend" %
            [bin, pkgInfo.basicInfo.name, backend], priority = HighPriority)
  else:
    display("Generating", ("documentation for $1 (from package $2) using $3 " &
            "backend") % [bin, pkgInfo.basicInfo.name, backend], priority = HighPriority)

  doCmd("$# $# --noNimblePath $# $# $#" %
        [pkgInfo.getNimBin(options).quoteShell,
         backend,
         join(args, " "),
         bin.quoteShell,
         options.action.additionalArguments.map(quoteShell).join(" ")])

  display("Success:", "Execution finished", Success, HighPriority)

  # Run the post hook for action if it exists
  discard execHook(options, options.action.typ, false)

proc search(options: Options) =
  ## Searches for matches in ``options.action.search``.
  ##
  ## Searches are done in a case insensitive way making all strings lower case.
  assert options.action.typ == actionSearch
  if options.action.search == @[]:
    raise nimbleError("Please specify a search string.")
  if needsRefresh(options):
    raise nimbleError("Please run nimble refresh.")
  let pkgList = getPackageList(options)
  var found = false
  template onFound {.dirty.} =
    echoPackage(pkg)
    if pkg.alias.len == 0 and options.queryVersions:
      echoPackageVersions(pkg)
    echo(" ")
    found = true
    break forPkg

  for pkg in pkgList:
    block forPkg:
      for word in options.action.search:
        # Search by name.
        if word.toLower() in pkg.name.toLower():
          onFound()
        # Search by tag.
        for tag in pkg.tags:
          if word.toLower() in tag.toLower():
            onFound()

  if not found:
    display("Error", "No package found.", Error, HighPriority)

proc list(options: Options) =
  if needsRefresh(options):
    raise nimbleError("Please run nimble refresh.")
  let pkgList = getPackageList(options)
  for pkg in pkgList:
    echoPackage(pkg)
    if pkg.alias.len == 0 and options.queryVersions:
      echoPackageVersions(pkg)
    echo(" ")

proc listInstalled(options: Options) =
  type
    VersionChecksumTuple = tuple[version: Version, checksum: Sha1Hash]
  var h: OrderedTable[string, seq[VersionChecksumTuple]]
  let pkgs = getInstalledPkgsMin(options.getPkgsDir(), options)
  for pkg in pkgs:
    let
      pName = pkg.basicInfo.name
      pVersion = pkg.basicInfo.version
      pChecksum = pkg.basicInfo.checksum
    if not h.hasKey(pName): h[pName] = @[]
    var s = h[pName]
    add(s, (pVersion, pChecksum))
    h[pName] = s

  h.sort(proc (a, b: (string, seq[VersionChecksumTuple])): int =
    cmpIgnoreCase(a[0], b[0]))
  for k in keys(h):
    echo k & "  [" & h[k].join(", ") & "]"

type VersionAndPath = tuple[version: Version, path: string]

proc listPaths(options: Options) =
  ## Loops over the specified packages displaying their installed paths.
  ##
  ## If there are several packages installed, all of them will be displayed.
  ## If any package name is not found, the proc displays a missing message and
  ## continues through the list, but at the end quits with a non zero exit
  ## error.
  ##
  ## On success the proc returns normally.

  cli.setSuppressMessages(true)
  assert options.action.typ == actionPath

  if options.action.packages.len == 0:
    raise nimbleError("A package name needs to be specified")

  var errors = 0
  let pkgs = getInstalledPkgsMin(options.getPkgsDir(), options)
  for name, version in options.action.packages.items:
    var installed: seq[VersionAndPath] = @[]
    # There may be several, list all available ones and sort by version.
    for pkg in pkgs:
      if name == pkg.basicInfo.name and withinRange(pkg.basicInfo.version, version):
        installed.add((pkg.basicInfo.version, pkg.getRealDir))

    if installed.len > 0:
      sort(installed, cmp[VersionAndPath], Descending)
      # The output for this command is used by tools so we do not use display().
      for pkg in installed:
        echo pkg.path
    else:
      display("Warning:", "Package '$1' is not installed" % name, Warning,
              MediumPriority)
      errors += 1
  if errors > 0:
    raise nimbleError(
        "At least one of the specified packages was not found")

proc join(x: seq[PkgTuple]; y: string): string =
  if x.len == 0: return ""
  result = x[0][0] & " " & $x[0][1]
  for i in 1 ..< x.len:
    result.add y
    result.add x[i][0] & " " & $x[i][1]

proc getPackageByPattern(pattern: string, options: Options): PackageInfo =
  ## Search for a package file using multiple strategies.
  if pattern == "":
    # Not specified - using current directory
    result = getPkgInfo(os.getCurrentDir(), options)
  elif pattern.splitFile.ext == ".nimble" and pattern.fileExists:
    # project file specified
    result = getPkgInfoFromFile(pattern, options)
  elif pattern.dirExists:
    # project directory specified
    result = getPkgInfo(pattern, options)
  else:
    # Last resort - attempt to read as package identifier
    let packages = getInstalledPkgsMin(options.getPkgsDir(), options)
    let identTuple = parseRequires(pattern)
    var skeletonInfo = initPackageInfo()
    if not findPkg(packages, identTuple, skeletonInfo):
      raise nimbleError(
          "Specified package not found"
      )
    result = getPkgInfoFromFile(skeletonInfo.myPath, options)

proc dump(options: Options) =
  cli.setSuppressMessages(true)
  let p = getPackageByPattern(options.action.projName, options)
  var j: JsonNode
  var s: string
  let json = options.dumpMode == kdumpJson
  if json: j = newJObject()
  template fn(key, val) =
    if json:
      when val is seq[PkgTuple]:
        # jsonutils.toJson would work but is only available since 1.3.5, so we
        # do it manually.
        j[key] = newJArray()
        for (name, ver) in val:
          j[key].add %{
            "name": % name,
            # we serialize both: `ver` may be more convenient for tooling
            # (no parsing needed); while `str` is more familiar.
            "str": % $ver,
            "ver": %* ver,
          }
      else:
        j[key] = %*val
    else:
      if s.len > 0: s.add "\n"
      s.add key & ": "
      when val is string:
        s.add val.escape
      else:
        s.add val.join(", ").escape
  fn "name", p.basicInfo.name
  fn "version", $p.basicInfo.version
  fn "author", p.author
  fn "desc", p.description
  fn "license", p.license
  fn "skipDirs", p.skipDirs
  fn "skipFiles", p.skipFiles
  fn "skipExt", p.skipExt
  fn "installDirs", p.installDirs
  fn "installFiles", p.installFiles
  fn "installExt", p.installExt
  fn "requires", p.requires
  for task, requirements in p.taskRequires:
    fn task & "Requires", requirements
  fn "bin", p.bin.keys.toSeq
  fn "binDir", p.binDir
  fn "srcDir", p.srcDir
  fn "backend", p.backend
  if json:
    s = j.pretty
  echo s

proc init(options: Options) =
  # Check whether the vcs is installed.
  let vcsBin = options.action.vcsOption
  if vcsBin != "" and findExe(vcsBin, true) == "":
    raise nimbleError("Please install git or mercurial first")

  # Determine the package name.
  let hasProjectName = options.action.projName != ""
  let pkgName =
    if options.action.projName != "":
      options.action.projName
    else:
      os.getCurrentDir().splitPath.tail.toValidPackageName()

  # Validate the package name.
  validatePackageName(pkgName)

  # Determine the package root.
  let pkgRoot =
    if not hasProjectName:
      os.getCurrentDir()
    else:
      os.getCurrentDir() / pkgName

  let nimbleFile = (pkgRoot / pkgName).changeFileExt("nimble")

  if fileExists(nimbleFile):
    let errMsg = "Nimble file already exists: $#" % nimbleFile
    raise nimbleError(errMsg)

  if options.forcePrompts != forcePromptYes:
    display(
      "Info:",
      "Package initialisation requires info which could not be inferred.\n" &
      "Default values are shown in square brackets, press\n" &
      "enter to use them.",
      priority = HighPriority
    )
  display("Using", "$# for new package name" % [pkgName.escape()],
    priority = HighPriority)

  # Determine author by running an external command
  proc getAuthorWithCmd(cmd: string): string =
    let (name, exitCode) = doCmdEx(cmd)
    if exitCode == QuitSuccess and name.len > 0:
      result = name.strip()
      display("Using", "$# for new package author" % [result],
        priority = HighPriority)

  # Determine package author via git/hg or asking
  proc getAuthor(): string =
    if findExe("git") != "":
      result = getAuthorWithCmd("git config --global user.name")
    elif findExe("hg") != "":
      result = getAuthorWithCmd("hg config ui.username")
    if result.len == 0:
      result = promptCustom(options, "Your name?", "Anonymous")
  let pkgAuthor = getAuthor()

  # Declare the src/ directory
  let pkgSrcDir = "src"
  display("Using", "$# for new package source directory" % [pkgSrcDir.escape()],
    priority = HighPriority)

  # Determine the type of package
  let pkgType = promptList(
    options,
    """Package type?
Library - provides functionality for other packages.
Binary  - produces an executable for the end-user.
Hybrid  - combination of library and binary

For more information see https://goo.gl/cm2RX5""",
    ["library", "binary", "hybrid"]
  )

  # Ask for package version.
  let pkgVersion = promptCustom(options, "Initial version of package?", "0.1.0")
  validateVersion(pkgVersion)

  # Ask for description
  let pkgDesc = promptCustom(options, "Package description?",
    "A new awesome nimble package")

  # Ask for license
  # License list is based on:
  # https://www.blackducksoftware.com/top-open-source-licenses
  var pkgLicense = options.promptList(
    """Package License?
This should ideally be a valid SPDX identifier. See https://spdx.org/licenses/.
""", [
    "MIT",
    "GPL-2.0",
    "Apache-2.0",
    "ISC",
    "GPL-3.0",
    "BSD-3-Clause",
    "LGPL-2.1",
    "LGPL-3.0",
    # LGPLv3 with static linking exception https://spdx.org/licenses/LGPL-3.0-linking-exception.html
    "LGPL-3.0-linking-exception",
    "EPL-2.0",
    "AGPL-3.0",
    # This is what npm calls "UNLICENSED" (which is too similar to "Unlicense")
    "Proprietary",
    "Other"
  ])

  if pkgLicense.toLower == "other":
    pkgLicense = promptCustom(options,
      """Package license?
Please specify a valid SPDX identifier.""",
      "MIT"
    )

  if pkgLicense in ["GPL-2.0", "GPL-3.0", "LGPL-2.1", "LGPL-3.0", "AGPL-3.0"]:
    let orLater = options.promptList(
      "\"Or any later version\" clause?", ["Yes", "No"])
    if orLater == "Yes":
      pkgLicense.add("-or-later")
    else:
      pkgLicense.add("-only")

  # Ask for Nim dependency
  let nimDepDef = getNimrodVersion(options)
  let pkgNimDep = promptCustom(options, "Lowest supported Nim version?",
    $nimDepDef)
  validateVersion(pkgNimDep)

  createPkgStructure(
    (
      pkgName,
      pkgVersion,
      pkgAuthor,
      pkgDesc,
      pkgLicense,
      pkgSrcDir,
      pkgNimDep,
      pkgType
    ),
    pkgRoot
  )

  # Create a git or hg repo in the new nimble project.
  if vcsBin != "":
    let cmd = fmt"cd {pkgRoot} && {vcsBin} init"
    let ret: tuple[output: string, exitCode: int] = execCmdEx(cmd)
    if ret.exitCode != 0: quit ret.output

    var ignoreFile = if vcsBin == "git": ".gitignore" else: ".hgignore"
    var fd = open(joinPath(pkgRoot, ignoreFile), fmWrite)
    fd.write(pkgName & "\n")
    fd.close()

  display("Success:", "Package $# created successfully" % [pkgName], Success,
    HighPriority)

proc removePackages(pkgs: HashSet[ReverseDependency], options: var Options) =
  for pkg in pkgs:
    let pkgInfo = pkg.toPkgInfo(options)
    case pkg.kind
    of rdkInstalled:
      pkgInfo.removePackage(options)
      display("Removed", $pkg, Success, HighPriority)
    of rdkDevelop:
      options.nimbleData.removeRevDep(pkgInfo)

proc collectNames(pkgs: HashSet[ReverseDependency],
                  includeDevelopRevDeps: bool): seq[string] =
  for pkg in pkgs:
    if pkg.kind != rdkDevelop or includeDevelopRevDeps:
      result.add $pkg

proc uninstall(options: var Options) =
  if options.action.packages.len == 0:
    raise nimbleError(
        "Please specify the package(s) to uninstall.")

  var pkgsToDelete: HashSet[ReverseDependency]
  # Do some verification.
  for pkgTup in options.action.packages:
    display("Looking", "for $1 ($2)" % [pkgTup.name, $pkgTup.ver],
            priority = HighPriority)
    let installedPkgs = getInstalledPkgsMin(options.getPkgsDir(), options)
    var pkgList = findAllPkgs(installedPkgs, pkgTup)
    if pkgList.len == 0:
      raise nimbleError("Package not found")

    display("Checking", "reverse dependencies", priority = HighPriority)
    for pkg in pkgList:
      # Check whether any packages depend on the ones the user is trying to
      # uninstall.
      if options.uninstallRevDeps:
        getAllRevDeps(options.nimbleData, pkg.toRevDep, pkgsToDelete)
      else:
        let revDeps = options.nimbleData.getRevDeps(pkg.toRevDep)
        if len(revDeps - pkgsToDelete) > 0:
          let pkgs = revDeps.collectNames(true)
          displayWarning(
            cannotUninstallPkgMsg(pkgTup.name, pkg.basicInfo.version, pkgs))
        else:
          pkgsToDelete.incl pkg.toRevDep

  if pkgsToDelete.len == 0:
    raise nimbleError("Failed uninstall - no packages to delete")

  if not options.prompt(pkgsToDelete.collectNames(false).promptRemovePkgsMsg):
    raise nimbleQuit()

  removePackages(pkgsToDelete, options)

proc listTasks(options: Options) =
  let nimbleFile = findNimbleFile(getCurrentDir(), true)
  nimscriptwrapper.listTasks(nimbleFile, options)

proc developAllDependencies(pkgInfo: PackageInfo, options: var Options)

proc saveLinkFile(pkgInfo: PackageInfo, options: Options) =
  let
    pkgName = pkgInfo.basicInfo.name
    pkgLinkDir = options.getPkgsLinksDir / pkgName.getLinkFileDir
    pkgLinkFilePath = pkgLinkDir / pkgName.getLinkFileName
    pkgLinkFileContent = pkgInfo.myPath & "\n" & pkgInfo.getNimbleFileDir

  if pkgLinkDir.dirExists and not options.prompt(
    &"The link file for {pkgName} already exists. Overwrite?"):
    return

  pkgLinkDir.createDir
  writeFile(pkgLinkFilePath, pkgLinkFileContent)
  displaySuccess(pkgLinkFileSavedMsg(pkgLinkFilePath))

proc developFromDir(pkgInfo: PackageInfo, options: var Options) =
  assert options.action.typ == actionDevelop,
    "This procedure should be called only when executing develop sub-command."

  let dir = pkgInfo.getNimbleFileDir()

  if options.depsOnly:
    raise nimbleError("Cannot develop dependencies only.")

  cd dir: # Make sure `execHook` executes the correct .nimble file.
    if not execHook(options, actionDevelop, true):
      raise nimbleError("Pre-hook prevented further execution.")

  if pkgInfo.bin.len > 0:
    displayWarning(
      "This package's binaries will not be compiled for development.")

  if options.developLocaldeps:
    var optsCopy = options
    optsCopy.nimbleDir = dir / nimbledeps
    optsCopy.nimbleData = newNimbleDataNode()
    optsCopy.startDir = dir
    createDir(optsCopy.getPkgsDir())
    cd dir:
      if options.action.withDependencies:
        developAllDependencies(pkgInfo, optsCopy)
      else:
        discard processAllDependencies(pkgInfo, optsCopy)
  else:
    if options.action.withDependencies:
      developAllDependencies(pkgInfo, options)
    else:
      # Dependencies need to be processed before the creation of the pkg dir.
      discard processAllDependencies(pkgInfo, options)

  if options.action.global:
    saveLinkFile(pkgInfo, options)

  displaySuccess(pkgSetupInDevModeMsg(pkgInfo.basicInfo.name, dir))

  # Execute the post-develop hook.
  cd dir:
    discard execHook(options, actionDevelop, false)

proc installDevelopPackage(pkgTup: PkgTuple, options: var Options):
    PackageInfo =
  let (meth, url, metadata) = getDownloadInfo(pkgTup, options, true)
  let subdir = metadata.getOrDefault("subdir")
  let downloadDir = getDevelopDownloadDir(url, subdir, options)

  if dirExists(downloadDir):
    if options.developWithDependencies:
      displayWarning(skipDownloadingInAlreadyExistingDirectoryMsg(
        downloadDir, pkgTup.name))
      let pkgInfo = getPkgInfo(downloadDir, options)
      developFromDir(pkgInfo, options)
      options.action.devActions.add(
        (datAdd, pkgInfo.getNimbleFileDir.normalizedPath))
      return pkgInfo
    else:
      raiseCannotCloneInExistingDirException(downloadDir)

  # Download the HEAD and make sure the full history is downloaded.
  let ver =
    if pkgTup.ver.kind == verAny:
      parseVersionRange("#head")
    else:
      pkgTup.ver

  discard downloadPkg(url, ver, meth, subdir, options, downloadDir,
                      vcsRevision = notSetSha1Hash)

  let pkgDir = downloadDir / subdir
  var pkgInfo = getPkgInfo(pkgDir, options)

  developFromDir(pkgInfo, options)
  options.action.devActions.add(
    (datAdd, pkgInfo.getNimbleFileDir.normalizedPath))
  return pkgInfo

proc developLockedDependencies(pkgInfo: PackageInfo,
    alreadyDownloaded: var HashSet[string], options: var Options) =
  ## Downloads for develop the dependencies from the lock file.
  for task, deps in pkgInfo.lockedDeps:
    for name, dep in deps:
      if dep.url.removeTrailingGitString notin alreadyDownloaded:
        let downloadResult = downloadDependency(name, dep, options)
        alreadyDownloaded.incl downloadResult.url.removeTrailingGitString
        options.action.devActions.add(
          (datAdd, downloadResult.downloadDir.normalizedPath))

proc check(alreadyDownloaded: HashSet[string], dep: PkgTuple,
           options: Options): bool =
  let (_, url, _) = getDownloadInfo(dep, options, false)
  alreadyDownloaded.contains url.removeTrailingGitString

proc developFreeDependencies(pkgInfo: PackageInfo,
                             alreadyDownloaded: var HashSet[string],
                             options: var Options) =
  # Downloads for develop the dependencies of `pkgInfo` (including transitive
  # ones) by recursively following the requires clauses in the Nimble files.
  assert not pkgInfo.isMinimal,
         "developFreeDependencies needs pkgInfo.requires"

  for dep in pkgInfo.requires:
    if dep.name.isNim:
      continue

    let resolvedDep = dep.resolveAlias(options)
    var found = alreadyDownloaded.check(dep, options)

    if not found and resolvedDep.name != dep.name:
      found = alreadyDownloaded.check(dep, options)
      if found:
        displayWarning(&"Develop package {dep.name} should be renamed to " &
                       resolvedDep.name)

    if found:
      continue

    let pkgInfo = installDevelopPackage(dep, options)
    alreadyDownloaded.incl pkgInfo.metaData.url.removeTrailingGitString

proc developAllDependencies(pkgInfo: PackageInfo, options: var Options) =
  ## Puts all dependencies of `pkgInfo` (including transitive ones) in develop
  ## mode by cloning their repositories.

  var alreadyDownloadedDependencies {.global.}: HashSet[string]
  alreadyDownloadedDependencies.incl pkgInfo.metaData.url.removeTrailingGitString

  if pkgInfo.hasLockedDeps():
    pkgInfo.developLockedDependencies(alreadyDownloadedDependencies, options)
  else:
    pkgInfo.developFreeDependencies(alreadyDownloadedDependencies, options)

proc updateSyncFile(dependentPkg: PackageInfo, options: Options)

proc updatePathsFile(pkgInfo: PackageInfo, options: Options) =
  let paths = pkgInfo.getDependenciesPaths(options)
  var pathsFileContent = "--noNimblePath\n"
  for path in paths:
    pathsFileContent &= &"--path:{path.escape}\n"
  var action = if fileExists(nimblePathsFileName): "updated" else: "generated"
  writeFile(nimblePathsFileName, pathsFileContent)
  displayInfo(&"\"{nimblePathsFileName}\" is {action}.")

proc develop(options: var Options) =
  let
    hasPackages = options.action.packages.len > 0
    hasPath = options.action.path.len > 0
    hasDevActions = options.action.devActions.len > 0
    hasDevFile = options.action.developFile.len > 0
    withDependencies = options.action.withDependencies

  var
    currentDirPkgInfo = initPackageInfo()
    hasError = false

  try:
    # Check whether the current directory is a package directory.
    currentDirPkgInfo = getPkgInfo(getCurrentDir(), options)
  except CatchableError as error:
    if hasDevActions and not hasDevFile:
      raise nimbleError(developOptionsWithoutDevelopFileMsg, details = error)

  if withDependencies and not hasPackages and not currentDirPkgInfo.isLoaded:
    raise nimbleError(developWithDependenciesWithoutPackagesMsg)

  if hasPath and not hasPackages and
     (not currentDirPkgInfo.isLoaded or not withDependencies):
    raise nimbleError(pathGivenButNoPkgsToDownloadMsg)

  if currentDirPkgInfo.isLoaded and (not hasPackages) and (not hasDevActions):
    developFromDir(currentDirPkgInfo, options)

  # Install each package.
  for pkgTup in options.action.packages:
    try:
      discard installDevelopPackage(pkgTup, options)
    except CatchableError as error:
      hasError = true
      displayError(&"Cannot install package \"{pkgTup}\" for develop.")
      displayDetails(error)

  if currentDirPkgInfo.isLoaded and not hasDevFile:
    options.action.developFile = developFileName

  if options.action.developFile.len > 0:
    hasError = not updateDevelopFile(currentDirPkgInfo, options) or hasError
    if currentDirPkgInfo.isLoaded and
       options.action.developFile == developFileName:
      # If we are updated package's develop file we have to update also
      # sync and paths files.
      updateSyncFile(currentDirPkgInfo, options)
      if fileExists(nimblePathsFileName):
        updatePathsFile(currentDirPkgInfo, options)

  if hasError:
    raise nimbleError(
      "There are some errors while executing the operation.",
      "See the log above for more details.")

proc test(options: Options) =
  ## Executes all tests starting with 't' in the ``tests`` directory.
  ## Subdirectories are not walked.
  var pkgInfo = getPkgInfo(getCurrentDir(), options)

  var
    files = toSeq(walkDir(getCurrentDir() / "tests"))
    tests, failures: int

  if files.len < 1:
    display("Warning:", "No tests found!", Warning, HighPriority)
    return

  if not execHook(options, actionCustom, true):
    raise nimbleError("Pre-hook prevented further execution.")

  files.sort((a, b) => cmp(a.path, b.path))

  for file in files:
    let (_, name, ext) = file.path.splitFile()
    if ext == ".nim" and name[0] == 't' and file.kind in {pcFile, pcLinkToFile}:
      var optsCopy = options
      optsCopy.action = Action(typ: actionCompile)
      optsCopy.action.file = file.path
      optsCopy.action.additionalArguments = options.action.arguments
      optsCopy.action.backend = pkgInfo.backend
      optsCopy.getCompilationFlags() = options.getCompilationFlags()
      # treat run flags as compile for default test task
      optsCopy.getCompilationFlags().add(options.action.custRunFlags)
      optsCopy.getCompilationFlags().add("-r")
      optsCopy.getCompilationFlags().add("--path:.")
      let
        binFileName = file.path.changeFileExt(ExeExt)
        existsBefore = fileExists(binFileName)

      if options.continueTestsOnFailure:
        inc tests
        try:
          execBackend(pkgInfo, optsCopy)
        except NimbleError:
          inc failures
      else:
        execBackend(pkgInfo, optsCopy)

      let
        existsAfter = fileExists(binFileName)
        canRemove = not existsBefore and existsAfter
      if canRemove:
        try:
          removeFile(binFileName)
        except OSError as exc:
          display("Warning:", "Failed to delete " & binFileName & ": " &
                  exc.msg, Warning, MediumPriority)

  if failures == 0:
    display("Success:", "All tests passed", Success, HighPriority)
  else:
    let error = "Only " & $(tests - failures) & "/" & $tests & " tests passed"
    display("Error:", error, Error, HighPriority)

  if not execHook(options, actionCustom, false):
    return

proc notInRequiredRangeMsg*(dependentPkg, dependencyPkg: PackageInfo,
                            versionRange: VersionRange): string =
  notInRequiredRangeMsg(dependencyPkg.basicInfo.name, dependencyPkg.getNimbleFileDir,
    $dependencyPkg.basicInfo.version, dependentPkg.basicInfo.name, dependentPkg.getNimbleFileDir,
    $versionRange)

proc validateDevelopDependenciesVersionRanges(dependentPkg: PackageInfo,
    dependencies: seq[PackageInfo], options: Options) =
  let allPackages = concat(@[dependentPkg], dependencies)
  let developDependencies = processDevelopDependencies(dependentPkg, options)
  var errors: seq[string]
  for pkg in allPackages:
    for dep in pkg.requires:
      if dep.ver.kind == verSpecial:
        # Develop packages versions are not being validated against the special
        # versions in the Nimble files requires clauses, because there is no
        # special versions for develop mode packages. If special version is
        # required then any version for the develop package is allowed.
        continue
      var depPkg = initPackageInfo()
      if not findPkg(developDependencies, dep, depPkg):
        # This dependency is not part of the develop mode dependencies.
        continue
      if not withinRange(depPkg, dep.ver):
        errors.add notInRequiredRangeMsg(pkg, depPkg, dep.ver)
  if errors.len > 0:
    raise nimbleError(invalidDevelopDependenciesVersionsMsg(errors))

proc check(options: Options) =
  try:
    let currentDir = getCurrentDir()
    let pkgInfo = getPkgInfo(currentDir, options, true)
    validateDevelopFile(pkgInfo, options)
    let dependencies = pkgInfo.processAllDependencies(options).toSeq
    validateDevelopDependenciesVersionRanges(pkgInfo, dependencies, options)
    displaySuccess(&"The package \"{pkgInfo.basicInfo.name}\" is valid.")
  except CatchableError as error:
    displayError(error)
    display("Failure:", validationFailedMsg, Error, HighPriority)
    raise nimbleQuit(QuitFailure)

proc updateSyncFile(dependentPkg: PackageInfo, options: Options) =
  # Updates the sync file with the current VCS revisions of develop mode
  # dependencies of the package `dependentPkg`.

  let developDeps = processDevelopDependencies(dependentPkg, options).toHashSet
  let syncFile = getSyncFile(dependentPkg)

  # Remove old data from the sync file
  syncFile.clear

  # Add all current develop packages' VCS revisions to the sync file.
  for dep in developDeps:
    syncFile.setDepVcsRevision(dep.basicInfo.name, dep.metaData.vcsRevision)

  syncFile.save

proc validateDevModeDepsWorkingCopiesBeforeLock(
    pkgInfo: PackageInfo, options: Options): ValidationErrors =
  ## Validates that the develop mode dependencies states are suitable for
  ## locking. They must be under version control, their working copies must be
  ## in a clean state and their current VCS revision must be present on some of
  ## the configured remotes.

  findValidationErrorsOfDevDepsWithLockFile(pkgInfo, options, result)

  # Those validation errors are not errors in the context of generating a lock
  # file.
  const notAnErrorSet = {
    vekWorkingCopyNeedsSync,
    vekWorkingCopyNeedsLock,
    vekWorkingCopyNeedsMerge,
    }

  # Remove not errors from the errors set.
  for name, error in common.dup(result):
    if error.kind in notAnErrorSet:
      result.del name

proc mergeLockedDependencies*(pkgInfo: PackageInfo, newDeps: LockFileDeps,
                              options: Options): LockFileDeps =
  ## Updates the lock file data of already generated lock file with the data
  ## from a new lock operation.
  # Copy across the data in the existing lock file
  for deps in pkgInfo.lockedDeps.values:
    for name, dep in deps:
      result[name] = dep

  let developDeps = pkgInfo.getDevelopDependencies(options)

  for name, dep in newDeps:
    if result.hasKey(name):
      # If the dependency is already present in the old lock file
      if developDeps.hasKey(name):
        # and it is a develop mode dependency update it with the newly locked
        # version,
        result[name] = dep
      else:
        # but if it is installed dependency just leave it at the current
        # version.
        discard
    else:
      # If the dependency is missing from the old develop file add it.
      result[name] = dep

  # Clean dependencies which are missing from the newly locked list.
  let deps = result
  for name, dep in deps:
    if not newDeps.hasKey(name):
      result.del name

proc displayLockOperationStart(lockFile: string): bool =
  ## Displays a proper log message for starting generating or updating the lock
  ## file of a package in directory `dir`.

  var doesLockFileExist = lockFile.fileExists
  let msg = if doesLockFileExist:
    updatingTheLockFileMsg
  else:
    generatingTheLockFileMsg
  displayInfo(msg)
  return doesLockFileExist

proc displayLockOperationFinish(didLockFileExist: bool) =
  ## Displays a proper log message for finished generation or update of a lock
  ## file.

  let msg = if didLockFileExist:
    lockFileIsUpdatedMsg
  else:
    lockFileIsGeneratedMsg
  displaySuccess(msg)

proc check(errors: var ValidationErrors, graph: LockFileDeps) =
  ## Checks that the dependency graph has no errors
  # throw error only for dependencies that are part of the graph
  for name, error in common.dup(errors):
    if name notin graph:
      errors.del name

  if errors.len > 0:
    raise validationErrors(errors)

proc lock(options: Options) =
  ## Generates a lock file for the package in the current directory or updates
  ## it if it already exists.

  let
    currentDir = getCurrentDir()
    pkgInfo = getPkgInfo(currentDir, options)
    currentLockFile = options.lockFile(currentDir)
    lockExists = displayLockOperationStart(currentLockFile)

  var errors = validateDevModeDepsWorkingCopiesBeforeLock(pkgInfo, options)

  # We need to process free dependencies for all tasks.
  # Then we can store each task as a seperate sub graph.
  let
    includeNim =
      pkgInfo.lockedDeps.contains("compiler") or
      pkgInfo.getDevelopDependencies(options).contains("nim")
    deps = pkgInfo.processFreeDependencies(pkgInfo.requires, options, includeNim)
  var fullDeps = deps # Deps shared by base and tasks

  # We need to seperate the graph into seperate tasks later
  var
    baseDepNames: HashSet[string]
    taskDepNames: Table[string, HashSet[string]]

  for dep in deps:
    baseDepNames.incl dep.name


  # Add each individual tasks as partial sub graphs
  for task, requires in pkgInfo.taskRequires:
    let newDeps = pkgInfo.processFreeDependencies(requires, options)
    {.push warning[ProveInit]: off.}
    # Don't know why this isn't considered proved
    let fullInfo = newDeps.toSeq().map(pkg => pkg.toFullInfo(options))
    {.push warning[ProveInit]: on.}
    pkgInfo.validateDevelopDependenciesVersionRanges(fullInfo, options)
    # Add in the dependencies that are in this task but not in base
    taskDepNames[task] = initHashSet[string]()
    for dep in newDeps:
      fullDeps.incl dep
      if dep.name notin baseDepNames:
        taskDepNames[task].incl dep.name
    # Reset the deps to what they were before hand.
    # Stops dependencies in this task overflowing into the next
    fullDeps.incl newDeps
  # Now build graph for all dependencies
  options.checkSatisfied(fullDeps)
  let fullInfo = fullDeps.toSeq().map(pkg => pkg.toFullInfo(options))
  pkgInfo.validateDevelopDependenciesVersionRanges(fullInfo, options)
  var graph = buildDependencyGraph(fullInfo, options)
  errors.check(graph)

  if lockExists:
    # If we already have a lock file, merge its data with the newly generated
    # one.
    #
    # IMPORTANT TODO:
    # To do this properly, an SMT solver is needed, but anyway, it seems that
    # currently Nimble does not check properly for `require` clauses
    # satisfaction between all packages, but just greedily picks the best
    # matching version of dependencies for the currently processed package.
    graph = mergeLockedDependencies(pkgInfo, graph, options)

  let (topologicalOrder, _) = topologicalSort(graph)
  var lockDeps: AllLockFileDeps
  # Now we break up tasks into seperate graphs
  lockDeps[noTask] = LockFileDeps()
  for task in pkgInfo.taskRequires.keys:
    lockDeps[task] = LockFileDeps()

  for dep in topologicalOrder:
    if dep in baseDepNames:
      lockDeps[noTask][dep] = graph[dep]
    else:
      # Add the dependency for any task that requires it
      for task in pkgInfo.taskRequires.keys:
        if dep in taskDepNames[task]:
          lockDeps[task][dep] = graph[dep]

  writeLockFile(currentLockFile, lockDeps)
  updateSyncFile(pkgInfo, options)
  displayLockOperationFinish(lockExists)


proc depsTree(options: Options) =
  ## Prints the dependency tree

  let pkgInfo = getPkgInfo(getCurrentDir(), options)

  var errors = validateDevModeDepsWorkingCopiesBeforeLock(pkgInfo, options)

  let dependencies =  pkgInfo.allDependencies(options).map(
    pkg => pkg.toFullInfo(options)).toSeq
  pkgInfo.validateDevelopDependenciesVersionRanges(dependencies, options)
  var dependencyGraph = buildDependencyGraph(dependencies, options)

  # delete errors for dependencies that aren't part of the graph
  for name, error in common.dup errors:
    if not dependencyGraph.contains name:
      errors.del name

  if options.action.format == "json":
    echo (%depsRecursive(pkgInfo, dependencies, errors)).pretty
  else:
    echo pkgInfo.basicInfo.name
    printDepsHumanReadable(pkgInfo, dependencies, 1, errors)

proc syncWorkingCopy(name: string, path: Path, dependentPkg: PackageInfo,
                     options: Options) =
  ## Syncs a working copy of a develop mode dependency of package `dependentPkg`
  ## with name `name` at path `path` with the revision from the lock file of
  ## `dependentPkg`.

  if options.offline:
    raise nimbleError("Cannot sync in offline mode.")

  displayInfo(&"Syncing working copy of package \"{name}\" at \"{path}\"...")

  let lockedDeps = dependentPkg.lockedDeps[noTask]
  assert lockedDeps.hasKey(name),
         &"Package \"{name}\" must be present in the lock file."

  let vcsRevision = lockedDeps[name].vcsRevision
  assert vcsRevision != path.getVcsRevision,
        "If here the working copy VCS revision must be different from the " &
        "revision written in the lock file."

  try:
    if not isVcsRevisionPresentOnSomeBranch(path, vcsRevision):
      # If the searched revision is not present on some local branch retrieve
      # changes sets from the remote branch corresponding to the local one.
      let (remote, branch) = getCorrespondingRemoteAndBranch(path)
      retrieveRemoteChangeSets(path, remote, branch)

    if not isVcsRevisionPresentOnSomeBranch(path, vcsRevision):
      # If the revision is still not found retrieve all remote change sets.
      retrieveRemoteChangeSets(path)

    let
      currentBranch = getCurrentBranch(path)
      localBranches = getBranchesOnWhichVcsRevisionIsPresent(
        path, vcsRevision, btLocal)
      remoteTrackingBranches = getBranchesOnWhichVcsRevisionIsPresent(
        path, vcsRevision, btRemoteTracking)
      allBranches = localBranches + remoteTrackingBranches

    var targetBranch =
      if allBranches.len == 0:
        # Te revision is not found on any branch.
        ""
      elif localBranches.len == 1:
        # If the revision is present on only one local branch switch to it.
        localBranches.toSeq[0]
      elif localBranches.contains(currentBranch):
        # If the current branch is among the local branches on which the
        # revision is found we have to stay to it.
        currentBranch
      elif remoteTrackingBranches.len == 1:
        # If the revision is found on only one remote tracking branch we have to
        # fast forward merge it to a corresponding local branch and to switch to
        # it.
        remoteTrackingBranches.toSeq[0]
      elif (let (hasBranch, branchName) = hasCorrespondingRemoteBranch(
              path, remoteTrackingBranches); hasBranch):
        # If the current branch has corresponding remote tracking branch on
        # which the revision is found we have to get the name of the remote
        # tracking branch in order to try to fast forward merge it to the local
        # branch.
        branchName
      else:
        # If the revision is found on several branches, but nighter of them is
        # the current one or a remote tracking branch corresponding to the
        # current one then give the user a choice to which branch to switch.
        options.promptList(
          &"The revision \"{vcsRevision}\" is found on multiple branches.\n" &
          "Choose a branch to switch to:",
          allBranches.toSeq.toOpenArray(0, allBranches.len - 1))

    if path.getVcsType == vcsTypeGit and
       remoteTrackingBranches.contains(targetBranch):
      # If the target branch is a remote tracking branch get all local branches
      # which track it.
      let localBranches = getLocalBranchesTrackingRemoteBranch(
        path, targetBranch)
      let localBranch =
        if localBranches.len == 0:
          # There is no local branch tracking the remote branch and we have to
          # get a name for a new branch.
          getLocalBranchName(path, targetBranch)
        elif localBranches.len == 1:
          # There is only one local branch tracking the remote branch.
          localBranches[0]
        else:
          # If there are multiple local branches which track the remote branch
          # then give the user a choice to which to try to fast forward merge
          # the remote branch.
          options.promptList("Choose local branch where to try to fast " &
                             &"forward merge \"{targetBranch}\":",
            localBranches.toOpenArray(0, localBranches.len - 1))
      fastForwardMerge(path, targetBranch, localBranch)
      targetBranch = localBranch

    if targetBranch != "":
      if targetBranch != currentBranch:
        switchBranch(path, targetBranch)
      if path.getVcsRevision != vcsRevision:
        setCurrentBranchToVcsRevision(path, vcsRevision)
    else:
      # If the revision is not found on any branch try to set the package
      # working copy to it in detached state. If the revision is completely
      # missing the operation will fail with exception.
      setWorkingCopyToVcsRevision(path, vcsRevision)

    displayInfo(pkgWorkingCopyIsSyncedMsg(name, $path))
  except CatchableError as error:
    displayError(&"Working copy of package \"{name}\" at path \"{path}\" " &
                  "cannot be synced.")
    displayDetails(error.msg)

proc sync(options: Options) =
  # Syncs working copies of the develop mode dependencies of the current
  # directory package with the revision data from the lock file.

  let currentDir = getCurrentDir()
  let pkgInfo = getPkgInfo(currentDir, options)

  if not pkgInfo.areLockedDepsLoaded:
    raise nimbleError("Cannot execute `sync` when lock file is missing.")

  if options.offline:
    raise nimbleError("Cannot execute `sync` in offline mode.")

  if not options.action.listOnly:
    # On `sync` we also want to update Nimble cache with the dependencies'
    # versions from the lock file.
    discard processLockedDependencies(pkgInfo, options)
    if fileExists(nimblePathsFileName):
      updatePathsFile(pkgInfo, options)

  var errors: ValidationErrors
  findValidationErrorsOfDevDepsWithLockFile(pkgInfo, options, errors)

  for name, error in common.dup(errors):
    if not pkgInfo.lockedDeps.hasPackage(name):
      errors.del name
    elif error.kind == vekWorkingCopyNeedsSync:
      if not options.action.listOnly:
        syncWorkingCopy(name, error.path, pkgInfo, options)
      else:
        displayInfo(pkgWorkingCopyNeedsSyncingMsg(name, $error.path))
      # Remove sync errors because we are doing sync.
      errors.del name

  updateSyncFile(pkgInfo, options)

  if errors.len > 0:
    raise validationErrors(errors)

proc append(existingContent: var string; newContent: string) =
  ## Appends `newContent` to the `existingContent` on a new line by inserting it
  ## if the new line doesn't already exist.
  if existingContent.len > 0 and existingContent[^1] != '\n':
    existingContent &= "\n"
  existingContent &= newContent

proc setupNimbleConfig(options: Options) =
  ## Creates `nimble.paths` file containing file system paths to the
  ## dependencies. Includes it in `config.nims` file to make them available
  ## for the compiler.
  const
    configFileVersion = 2
    sectionEnd = "# end Nimble config"
    sectionStart = "# begin Nimble config"
    configFileHeader = &"# begin Nimble config (version {configFileVersion})"
    configFileContentNoLock = fmt"""
{configFileHeader}
when withDir(thisDir(), system.fileExists("{nimblePathsFileName}")):
  include "{nimblePathsFileName}"
{sectionEnd}
"""
    configFileContentWithLock = fmt"""
{configFileHeader}
--noNimblePath
when withDir(thisDir(), system.fileExists("{nimblePathsFileName}")):
  include "{nimblePathsFileName}"
{sectionEnd}
"""

  let
    currentDir = getCurrentDir()
    pkgInfo = getPkgInfo(currentDir, options)
    lockFileExists = options.lockFile(currentDir).fileExists
    configFileContent = if lockFileExists: configFileContentWithLock
                        else: configFileContentNoLock

  updatePathsFile(pkgInfo, options)

  var
    writeFile = false
    fileContent: string

  if fileExists(nimbleConfigFileName):
    fileContent = readFile(nimbleConfigFileName)
    if not fileContent.contains(configFileContent):
      let
        startIndex = fileContent.find(sectionStart)
        endIndex = fileContent.find(sectionEnd)
      if startIndex >= 0 and endIndex >= 0:
        fileContent.delete(startIndex..endIndex + sectionEnd.len - 1)

      fileContent.append(configFileContent)
      writeFile = true
  else:
    fileContent.append(configFileContent)
    writeFile = true

  if writeFile:
    writeFile(nimbleConfigFileName, fileContent)
    displayInfo(&"\"{nimbleConfigFileName}\" is set up.")
  else:
    displayInfo(&"\"{nimbleConfigFileName}\" is already set up.")

proc setupVcsIgnoreFile =
  ## Adds the names of some files which should not be committed to the VCS
  ## ignore file.
  let
    currentDir = getCurrentDir()
    vcsIgnoreFileName = case currentDir.getVcsType
      of vcsTypeGit: gitIgnoreFileName
      of vcsTypeHg: hgIgnoreFileName
      of vcsTypeNone: ""

  if vcsIgnoreFileName.len == 0:
    return

  var
    writeFile = false
    fileContent: string

  if fileExists(vcsIgnoreFileName):
    fileContent = readFile(vcsIgnoreFileName)
    if not fileContent.contains(developFileName):
      fileContent.append(developFileName)
      writeFile = true
    if not fileContent.contains(nimblePathsFileName):
      fileContent.append(nimblePathsFileName)
      writeFile = true
  else:
    fileContent.append(developFileName)
    fileContent.append(nimblePathsFileName)
    writeFile = true

  if writeFile:
    writeFile(vcsIgnoreFileName, fileContent & "\n")

proc setup(options: Options) =
  setupNimbleConfig(options)
  setupVcsIgnoreFile()

proc getPackageForAction(pkgInfo: PackageInfo, options: Options): PackageInfo =
  ## Returns the `PackageInfo` for the package in `pkgInfo`'s dependencies tree
  ## with the name specified in `options.package`. If `options.package` is empty
  ## or it matches the name of the `pkgInfo` then `pkgInfo` is returned. Raises
  ## a `NimbleError` if the package with the provided name is not found.

  result = initPackageInfo()

  if options.package.len == 0 or pkgInfo.basicInfo.name == options.package:
    return pkgInfo

  let deps = pkgInfo.processAllDependencies(options)
  for dep in deps:
    if dep.basicInfo.name == options.package:
      return dep.toFullInfo(options)

  raise nimbleError(notFoundPkgWithNameInPkgDepTree(options.package))

proc run(options: Options) =
  var pkgInfo = getPkgInfo(getCurrentDir(), options)
  pkgInfo = getPackageForAction(pkgInfo, options)

  let binary = options.getCompilationBinary(pkgInfo).get("")
  if binary.len == 0:
    raise nimbleError("Please specify a binary to run")

  if binary notin pkgInfo.bin:
    raise nimbleError(binaryNotDefinedInPkgMsg(binary, pkgInfo.basicInfo.name))

  if pkgInfo.isLink:
    # If this is not installed package then build the binary.
    pkgInfo.build(options)
  elif options.getCompilationFlags.len > 0:
    displayWarning(ignoringCompilationFlagsMsg)

  let binaryPath = pkgInfo.getOutputDir(binary)
  let cmd = quoteShellCommand(binaryPath & options.action.runFlags)
  displayDebug("Executing", cmd)

  let exitCode = cmd.execCmd
  raise nimbleQuit(exitCode)

proc doAction(options: var Options) =
  if options.showHelp:
    writeHelp()
  if options.showVersion:
    writeVersion()

  if options.action.typ in {actionTasks, actionRun, actionBuild, actionCompile}:
    # Implicitly disable package validation for these commands.
    options.disableValidation = true

  case options.action.typ
  of actionRefresh:
    refresh(options)
  of actionInstall:
    let (_, pkgInfo) = install(options.action.packages, options,
                               doPrompt = true,
                               first = true,
                               fromLockFile = false)
    if options.action.packages.len == 0:
      nimScriptHint(pkgInfo)
    if pkgInfo.foreignDeps.len > 0:
      display("Hint:", "This package requires some external dependencies.",
              Warning, HighPriority)
      display("Hint:", "To install them you may be able to run:",
              Warning, HighPriority)
      for i in 0..<pkgInfo.foreignDeps.len:
        display("Hint:", "  " & pkgInfo.foreignDeps[i], Warning, HighPriority)
  of actionUninstall:
    uninstall(options)
  of actionSearch:
    search(options)
  of actionList:
    if options.queryInstalled: listInstalled(options)
    else: list(options)
  of actionPath:
    listPaths(options)
  of actionBuild:
    build(options)
  of actionClean:
    clean(options)
  of actionRun:
    run(options)
  of actionCompile, actionDoc:
    var pkgInfo = getPkgInfo(getCurrentDir(), options)
    execBackend(pkgInfo, options)
  of actionInit:
    init(options)
  of actionPublish:
    var pkgInfo = getPkgInfo(getCurrentDir(), options)
    publish(pkgInfo, options)
  of actionDump:
    dump(options)
  of actionTasks:
    listTasks(options)
  of actionDevelop:
    develop(options)
  of actionCheck:
    check(options)
  of actionLock:
    lock(options)
  of actionDeps:
    depsTree(options)
  of actionSync:
    sync(options)
  of actionSetup:
    setup(options)
  of actionNil:
    assert false
  of actionCustom:
    var optsCopy = options
    optsCopy.task = options.action.command.normalize
    let
      nimbleFile = findNimbleFile(getCurrentDir(), true)
      pkgInfo = getPkgInfoFromFile(nimbleFile, optsCopy)

    if optsCopy.task in pkgInfo.nimbleTasks:
      # Make sure we have dependencies for the task.
      # We do that here to make sure that any binaries from dependencies
      # are installed
      discard pkgInfo.processAllDependencies(optsCopy)
      # If valid task defined in nimscript, run it
      var execResult: ExecutionResult[bool]
      if execCustom(nimbleFile, optsCopy, execResult):
        if execResult.hasTaskRequestedCommand():
          var options = execResult.getOptionsForCommand(optsCopy)
          doAction(options)
    elif optsCopy.task == "test":
      # If there is no task defined for the `test` task, we run the pre-defined
      # fallback logic.
      test(optsCopy)
    else:
      raise nimbleError(msg = "Could not find task $1 in $2" %
                              [options.action.command, nimbleFile],
                        hint = "Run `nimble --help` and/or `nimble tasks` for" &
                               " a list of possible commands.")

proc useLockedNim(options: var Options, realDir: string) =
  const binaryName = when defined(windows): "nim.exe" else: "nim"
  let nim = realDir / "bin" / binaryName

  if not fileExists(nim):
    raise nimbleError("Trying to use nim from $1 " % realDir,
                      "If you are using develop mode nim make sure to compile it.")

  options.nim = nim
  let separator = when defined(windows): ";" else: ":"

  putEnv("PATH", realDir / "bin" & separator & getEnv("PATH"))
  display("Info:", "using $1 for compilation" % options.nim, priority = HighPriority)

proc setNimBin*(options: var Options) =
  # Find nim binary and set into options
  if options.nim.len != 0:
    # --nim:<path> takes priority...
    if options.nim.splitPath().head.len == 0:
      # Just filename, search in PATH - nim_temp shortcut
      let pnim = findExe(options.nim)
      if pnim.len != 0:
        options.nim = pnim
      else:
        raise nimbleError(
          "Unable to find `$1` in $PATH" % options.nim)
    elif not options.nim.isAbsolute():
      # Relative path
      options.nim = expandTilde(options.nim).absolutePath()

    if not fileExists(options.nim):
      raise nimbleError("Unable to find `$1`" % options.nim)
  else:
    let lockFile = options.lockFile(getCurrentDir())

    if lockFile.fileExists and not options.disableLockFile and not options.useSystemNim:
      for name, dep in lockFile.getLockedDependencies.lockedDepsFor(options):
        if name.isNim:
          if isInstalled(name, dep, options):
            options.useLockedNim(getDependencyDir(name, dep, options))
          elif not options.offline:
            let
              downloadResult = downloadDependency(name, dep, options, false)
              command = when defined(windows): "build_all.bat" else: "./build_all.sh"
            cd downloadResult.downloadDir:
              tryDoCmdEx(command)
            options.useLockedNim(downloadResult.downloadDir)
            let pkgInfo = installDependency(initTable[string, LockFileDep](), downloadResult, options, @[])
            options.useLockedNim(pkgInfo.getRealDir)
          break

    # Search PATH
    if options.nim.len == 0: options.nim = findExe("nim")

    if options.nim.len == 0:
      # Nim not found in PATH
      raise nimbleError(
        "Unable to find `nim` binary - add to $PATH or use `--nim`")

when isMainModule:
  var exitCode = QuitSuccess

  var opt: Options
  try:
    opt = parseCmdLine()
    opt.setNimbleDir
    opt.loadNimbleData
    opt.setNimBin
    opt.doAction()
  except NimbleQuit as quit:
    exitCode = quit.exitCode
  except CatchableError as error:
    exitCode = QuitFailure
    displayTip()
    echo error.getStackTrace()
    displayError(error)
  finally:
    try:
      let folder = getNimbleTempDir()
      if opt.shouldRemoveTmp(folder):
        removeDir(folder)
    except CatchableError as error:
      displayWarning("Couldn't remove Nimble's temp dir")
      displayDetails(error)

    try:
      saveNimbleData(opt)
    except CatchableError as error:
      exitCode = QuitFailure
      displayError(&"Couldn't save \"{nimbleDataFileName}\".")
      displayDetails(error)

  quit(exitCode)
