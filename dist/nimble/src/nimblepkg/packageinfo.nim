# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

# Stdlib imports
import system except TResult
import hashes, json, strutils, os, sets, tables, times, httpclient, strformat
from net import SslError

# Local imports
import version, tools, common, options, cli, config, lockfile, packageinfotypes,
       packagemetadatafile, sha1hashes

proc initPackageInfo*(): PackageInfo =
  result = PackageInfo(
    basicInfo: ("", notSetVersion, notSetSha1Hash),
    metaData: initPackageMetaData())

proc initPackage*(): Package =
  result = Package(version: notSetVersion)

proc isLoaded*(pkgInfo: PackageInfo): bool =
  return pkgInfo.myPath.len > 0

proc assertIsLoaded*(pkgInfo: PackageInfo) =
  assert pkgInfo.isLoaded, "The package info must be loaded. "

proc areLockedDepsLoaded*(pkgInfo: PackageInfo): bool =
  pkgInfo.lockedDeps.len > 0

proc hasMetaData*(pkgInfo: PackageInfo): bool =
  # if the package info has loaded meta data its files list have to be not empty
  pkgInfo.metaData.files.len > 0

proc initPackageInfo*(options: Options, filePath: string): PackageInfo =
  result = initPackageInfo()
  let (fileDir, fileName, _) = filePath.splitFile
  result.myPath = filePath
  result.basicInfo.name = fileName
  result.backend = "c"
  if not options.disableLockFile:
    result.lockedDeps = options.lockFile(fileDir).getLockedDependencies()

proc toValidPackageName*(name: string): string =
  for c in name:
    case c
    of '_', '-':
      if result[^1] != '_': result.add('_')
    of AllChars - IdentChars - {'-'}: discard
    else: result.add(c)

proc optionalField(obj: JsonNode, name: string, default = ""): string =
  ## Queries ``obj`` for the optional ``name`` string.
  ##
  ## Returns the value of ``name`` if it is a valid string, or aborts execution
  ## if the field exists but is not of string type. If ``name`` is not present,
  ## returns ``default``.
  if hasKey(obj, name):
    if obj[name].kind == JString:
      return obj[name].str
    else:
      raise nimbleError("Corrupted packages.json file. " & name &
          " field is of unexpected type.")
  else: return default

proc requiredField(obj: JsonNode, name: string): string =
  ## Queries ``obj`` for the required ``name`` string.
  ##
  ## Aborts execution if the field does not exist or is of invalid json type.
  result = optionalField(obj, name)
  if result.len == 0:
    raise nimbleError(
        "Package in packages.json file does not contain a " & name & " field.")

proc parseDownloadMethod*(meth: string): DownloadMethod =
  case meth
  of "git": return DownloadMethod.git
  of "hg", "mercurial": return DownloadMethod.hg
  else:
    raise nimbleError("Invalid download method: " & meth)

{.warning[ProveInit]: off.}
proc fromJson(obj: JSonNode): Package =
  ## Constructs a Package object from a JSON node.
  ##
  ## Aborts execution if the JSON node doesn't contain the required fields.
  result.name = obj.requiredField("name")
  if obj.hasKey("alias"):
    result.alias = obj.requiredField("alias")
  else:
    result.alias = ""
    result.version = newVersion(obj.optionalField("version"))
    result.url = obj.requiredField("url")
    result.downloadMethod = obj.requiredField("method").parseDownloadMethod
    result.dvcsTag = obj.optionalField("dvcs-tag")
    result.license = obj.requiredField("license")
    result.tags = @[]
    for t in obj["tags"]:
      result.tags.add(t.str)
    result.description = obj.optionalField("description")
    result.web = obj.optionalField("web")
{.warning[ProveInit]: on.}

proc needsRefresh*(options: Options): bool =
  ## Determines whether a ``nimble refresh`` is needed.
  ##
  ## In the future this will check a stored time stamp to determine how long
  ## ago the package list was refreshed.
  result = true
  for name, list in options.config.packageLists:
    if fileExists(options.getNimbleDir() / "packages_" & name & ".json"):
      result = false

proc validatePackagesList(path: string): bool =
  ## Determines whether package list at ``path`` is valid.
  try:
    let pkgList = parseFile(path)
    if pkgList.kind == JArray:
      if pkgList.len == 0:
        display("Warning:", path & " contains no packages.", Warning,
                HighPriority)
      return true
  except ValueError, JsonParsingError:
    return false

proc fetchList*(list: PackageList, options: Options) =
  ## Downloads or copies the specified package list and saves it in $nimbleDir.
  let verb = if list.urls.len > 0: "Downloading" else: "Copying"
  display(verb, list.name & " package list", priority = HighPriority)

  var
    lastError = ""
    copyFromPath = ""
  if list.urls.len > 0:
    for i in 0 ..< list.urls.len:
      let url = list.urls[i]
      display("Trying", url)
      let tempPath = options.getNimbleDir() / "packages_temp.json"

      # Grab the proxy
      let proxy = getProxy(options)
      if not proxy.isNil:
        var maskedUrl = proxy.url
        if maskedUrl.password.len > 0: maskedUrl.password = "***"
        display("Connecting", "to proxy at " & $maskedUrl,
                priority = LowPriority)

      try:
        let ctx = newSSLContext(options.disableSslCertCheck)
        let client = newHttpClient(proxy = proxy, sslContext = ctx)
        client.downloadFile(url, tempPath)
      except SslError:
        let message = "Failed to verify the SSL certificate for " & url
        raise nimbleError(message, "Use --noSSLCheck to ignore this error.")

      except:
        let message = "Could not download: " & getCurrentExceptionMsg()
        display("Warning:", message, Warning)
        lastError = message
        continue

      if not validatePackagesList(tempPath):
        lastError = "Downloaded packages.json file is invalid"
        display("Warning:", lastError & ", discarding.", Warning)
        continue

      copyFromPath = tempPath
      display("Success", "Package list downloaded.", Success, HighPriority)
      lastError = ""
      break

  elif list.path != "":
    if not validatePackagesList(list.path):
      lastError = "Copied packages.json file is invalid"
      display("Warning:", lastError & ", discarding.", Warning)
    else:
      copyFromPath = list.path
      display("Success", "Package list copied.", Success, HighPriority)

  if lastError.len != 0:
    raise nimbleError("Refresh failed\n" & lastError)

  if copyFromPath.len > 0:
    copyFile(copyFromPath,
        options.getNimbleDir() / "packages_$1.json" % list.name.toLowerAscii())

# Cache after first call
var
  gPackageJson: Table[string, JsonNode]
proc readPackageList(name: string, options: Options, ignorePackageCache = false): JsonNode =
  # If packages.json is not present ask the user if they want to download it.
  if (not ignorePackageCache) and gPackageJson.hasKey(name):
    return gPackageJson[name]

  if needsRefresh(options):
    if options.prompt("No local packages.json found, download it from " &
            "internet?"):
      for name, list in options.config.packageLists:
        fetchList(list, options)
    else:
      # The user might not need a package list for now. So let's try
      # going further.
      gPackageJson[name] = newJArray()
      return gPackageJson[name]
  let file = options.getNimbleDir() / "packages_" & name.toLowerAscii() & ".json"
  if file.fileExists:
    gPackageJson[name] = parseFile(file)
  else:
    gPackageJson[name] = newJArray()
  return gPackageJson[name]

proc getPackage*(pkg: string, options: Options, resPkg: var Package, ignorePackageCache = false): bool
proc resolveAlias(pkg: Package, options: Options): Package =
  result = pkg
  # Resolve alias.
  if pkg.alias.len > 0:
    display("Warning:", "The $1 package has been renamed to $2" %
            [pkg.name, pkg.alias], Warning, HighPriority)
    if not getPackage(pkg.alias, options, result):
      raise nimbleError("Alias for package not found: " &
                         pkg.alias)

proc getPackage*(pkg: string, options: Options, resPkg: var Package, ignorePackageCache = false): bool =
  ## Searches any packages.json files defined in ``options.config.packageLists``
  ## Saves the found package into ``resPkg``.
  ##
  ## Pass in ``pkg`` the name of the package you are searching for. As
  ## convenience the proc returns a boolean specifying if the ``resPkg`` was
  ## successfully filled with good data.
  ##
  ## Aliases are handled and resolved.
  for name, list in options.config.packageLists:
    display("Reading", "$1 package list" % name, priority = LowPriority)
    let packages = readPackageList(name, options, ignorePackageCache)
    for p in packages:
      if normalize(p["name"].str) == normalize(pkg):
        resPkg = p.fromJson()
        resPkg = resolveAlias(resPkg, options)
        return true

{.warning[ProveInit]: off.}
proc getPackage*(name: string, options: Options): Package =
  let success = getPackage(name, options, result)
  if not success:
    raise nimbleError(
      "Cannot find package with name '" & name & "'.")
{.warning[ProveInit]: on.}

proc getPackageList*(options: Options): seq[Package] =
  ## Returns the list of packages found in the downloaded packages.json files.
  var namesAdded: HashSet[string]
  for name, list in options.config.packageLists:
    let packages = readPackageList(name, options)
    for p in packages:
      let pkg: Package = p.fromJson()
      if pkg.name notin namesAdded:
        result.add(pkg)
        namesAdded.incl(pkg.name)

proc findNimbleFile*(dir: string; error: bool): string =
  var hits = 0
  for kind, path in walkDir(dir):
    if kind in {pcFile, pcLinkToFile}:
      let ext = path.splitFile.ext
      case ext
      of ".babel", ".nimble":
        result = path
        inc hits
      else: discard
  if hits >= 2:
    raise nimbleError(
        "Only one .nimble file should be present in " & dir)
  elif hits == 0:
    if error:
      raise nimbleError(
        "Could not find a file with a .nimble extension inside the specified " &
        "directory: $1" % dir)
    else:
      displayWarning(&"No .nimble file found for {dir}")

proc setNameVersionChecksum*(pkgInfo: var PackageInfo, pkgDir: string) =
  let (name, version, checksum) = getNameVersionChecksum(pkgDir)
  pkgInfo.basicInfo.name = name
  if pkgInfo.basicInfo.version == notSetVersion:
    # if there is no previously set version from the `.nimble` file
    pkgInfo.basicInfo.version = version
  pkgInfo.metaData.specialVersions.incl version
  pkgInfo.basicInfo.checksum = checksum

proc getInstalledPackageMin*(options: Options, pkgDir, nimbleFilePath: string): PackageInfo =
  result = initPackageInfo(options, nimbleFilePath)
  setNameVersionChecksum(result, pkgDir)
  result.isMinimal = true
  result.isInstalled = true
  fillMetaData(result, pkgDir, false)

proc getInstalledPkgsMin*(libsDir: string, options: Options): seq[PackageInfo] =
  ## Gets a list of installed packages. The resulting package info is
  ## minimal. This has the advantage that it does not depend on the
  ## ``packageparser`` module, and so can be used by ``nimscriptwrapper``.
  ##
  ## ``libsDir`` is in most cases: ~/.nimble/pkgs/ (options.getPkgsDir)
  result = @[]
  for kind, path in walkDir(libsDir):
    if kind == pcDir:
      let nimbleFile = findNimbleFile(path, false)
      if nimbleFile != "":
        let pkg = getInstalledPackageMin(options, path, nimbleFile)
        result.add pkg

proc withinRange*(pkgInfo: PackageInfo, verRange: VersionRange): bool =
  ## Determines whether the specified package's version is within the specified
  ## range. As the ordinary version is always added to the special versions set
  ## checking only the special versions is enough.
  return withinRange(pkgInfo.metaData.specialVersions, verRange)

proc resolveAlias*(dep: PkgTuple, options: Options): PkgTuple =
  ## Looks up the specified ``dep.name`` in the packages.json files to resolve
  ## a potential alias into the package's real name.
  result = dep
  var pkg = initPackage()
  # TODO: This needs better caching.
  if getPackage(dep.name, options, pkg):
    # The resulting ``pkg`` will contain the resolved name or the original if
    # no alias is present.
    result.name = pkg.name

proc findPkg*(pkglist: seq[PackageInfo], dep: PkgTuple,
              r: var PackageInfo): bool =
  ## Searches ``pkglist`` for a package of which version is within the range
  ## of ``dep.ver``. ``True`` is returned if a package is found. If multiple
  ## packages are found the newest one is returned (the one with the highest
  ## version number). If there is a package in develop mode indicated by its
  ## `isLink` field being `true`, it should be only one for given package name,
  ## and if its version is in the required range, it will be treated with the
  ## highest priority.
  ##
  ## **Note**: dep.name here could be a URL, hence the need for pkglist.meta.
  for pkg in pkglist:
    if cmpIgnoreStyle(pkg.basicInfo.name, dep.name) != 0 and
       cmpIgnoreStyle(pkg.metaData.url, dep.name) != 0: continue
    if pkg.isLink:
      # If `pkg.isLink` this is a develop mode package and develop mode packages
      # are always with higher priority than installed packages. Version range
      # is not being considered for them.
      r = pkg
      return true
    elif withinRange(pkg, dep.ver):
      let isNewer = r.basicInfo.version < pkg.basicInfo.version
      if not result or isNewer:
        r = pkg
        result = true

proc findAllPkgs*(pkglist: seq[PackageInfo], dep: PkgTuple): seq[PackageInfo] =
  ## Searches ``pkglist`` for packages of which version is within the range
  ## of ``dep.ver``. This is similar to ``findPkg`` but returns multiple
  ## packages if multiple are found.
  result = @[]
  for pkg in pkglist:
    if cmpIgnoreStyle(pkg.basicInfo.name, dep.name) != 0 and
       cmpIgnoreStyle(pkg.metaData.url, dep.name) != 0: continue
    if withinRange(pkg, dep.ver):
      result.add pkg


proc getRealDir*(pkgInfo: PackageInfo): string =
  ## Returns the directory containing the package source files.
  if pkgInfo.srcDir != "" and (not pkgInfo.isInstalled or pkgInfo.isLink):
    result = pkgInfo.getNimbleFileDir() / pkgInfo.srcDir
  else:
    result = pkgInfo.getNimbleFileDir()

proc getOutputDir*(pkgInfo: PackageInfo, bin: string): string =
  ## Returns a binary output dir for the package.
  if pkgInfo.binDir != "":
    result = pkgInfo.getNimbleFileDir() / pkgInfo.binDir / bin
  else:
    result = pkgInfo.mypath.splitFile.dir / bin
  if bin.len != 0 and dirExists(result):
    result &= ".out"

proc echoPackage*(pkg: Package) =
  echo(pkg.name & ":")
  if pkg.alias.len > 0:
    echo("  Alias for ", pkg.alias)
  else:
    echo("  url:         " & pkg.url & " (" & $pkg.downloadMethod & ")")
    echo("  tags:        " & pkg.tags.join(", "))
    echo("  description: " & pkg.description)
    echo("  license:     " & pkg.license)
    if pkg.web.len > 0:
      echo("  website:     " & pkg.web)

proc getDownloadDirName*(pkg: Package, verRange: VersionRange): string =
  result = pkg.name
  let verSimple = getSimpleString(verRange)
  if verSimple != "":
    result.add "_"
    result.add verSimple

proc checkInstallFile(pkgInfo: PackageInfo,
                      origDir, file: string): bool =
  ## Checks whether ``file`` should be installed.
  ## ``True`` means file should be skipped.

  for ignoreFile in pkgInfo.skipFiles:
    if ignoreFile.endswith("nimble"):
      raise nimbleError(ignoreFile & " must be installed.")
    if samePaths(file, origDir / ignoreFile):
      result = true
      break

  for ignoreExt in pkgInfo.skipExt:
    if file.splitFile.ext == ('.' & ignoreExt):
      result = true
      break

  if file.splitFile().name[0] == '.': result = true

proc checkInstallDir(pkgInfo: PackageInfo,
                     origDir, dir: string): bool =
  ## Determines whether ``dir`` should be installed.
  ## ``True`` means dir should be skipped.
  for ignoreDir in pkgInfo.skipDirs:
    if samePaths(dir, origDir / ignoreDir):
      result = true
      break

  let thisDir = splitPath(dir).tail
  assert thisDir != ""
  if thisDir[0] == '.': result = true
  if thisDir == "nimcache": result = true

proc iterFilesWithExt(dir: string, pkgInfo: PackageInfo,
                      action: proc (f: string)) =
  ## Runs `action` for each filename of the files that have a whitelisted
  ## file extension.
  for kind, path in walkDir(dir):
    if kind == pcDir:
      iterFilesWithExt(path, pkgInfo, action)
    else:
      if path.splitFile.ext.substr(1) in pkgInfo.installExt:
        action(path)

proc iterFilesInDir(dir: string, action: proc (f: string)) =
  ## Runs `action` for each file in ``dir`` and any
  ## subdirectories that are in it.
  for kind, path in walkDir(dir):
    if kind == pcDir:
      iterFilesInDir(path, action)
    else:
      action(path)

proc iterInstallFiles*(realDir: string, pkgInfo: PackageInfo,
                       options: Options, action: proc (f: string)) =
  ## Runs `action` for each file within the ``realDir`` that should be
  ## installed.
  let whitelistMode =
          pkgInfo.installDirs.len != 0 or
          pkgInfo.installFiles.len != 0 or
          pkgInfo.installExt.len != 0
  if whitelistMode:
    for file in pkgInfo.installFiles:
      let src = realDir / file
      if not src.fileExists():
        if options.prompt("Missing file " & src & ". Continue?"):
          continue
        else:
          raise nimbleQuit()

      action(src)

    for dir in pkgInfo.installDirs:
      # TODO: Allow skipping files inside dirs?
      let src = realDir / dir
      if not src.dirExists():
        if options.prompt("Missing directory " & src & ". Continue?"):
          continue
        else:
          raise nimbleQuit()

      iterFilesInDir(src, action)

    iterFilesWithExt(realDir, pkgInfo, action)
  else:
    for kind, file in walkDir(realDir):
      if kind == pcDir:
        let skip = pkgInfo.checkInstallDir(realDir, file)
        if skip: continue
        # we also have to stop recursing if we reach an in-place nimbleDir
        if file == options.getNimbleDir().expandFilename(): continue

        iterInstallFiles(file, pkgInfo, options, action)
      else:
        let skip = pkgInfo.checkInstallFile(realDir, file)
        if skip: continue

        action(file)

proc needsRebuild*(pkgInfo: PackageInfo, bin: string, dir: string, options: Options): bool =
  if options.action.typ != actionInstall:
    return true
  if not options.action.noRebuild:
    return true

  let binTimestamp = getFileInfo(bin).lastWriteTime
  var rebuild = false
  iterFilesWithExt(dir, pkgInfo,
    proc (file: string) =
      let srcTimestamp = getFileInfo(file).lastWriteTime
      if binTimestamp < srcTimestamp:
        rebuild = true
  )
  return rebuild

proc getCacheDir*(pkgInfo: PackageBasicInfo): string =
  &"{pkgInfo.name}-{pkgInfo.version}-{$pkgInfo.checksum}"

proc getPkgDest*(pkgInfo: PackageBasicInfo, options: Options): string =
  options.getPkgsDir() / pkgInfo.getCacheDir()

proc getPkgDest*(pkgInfo: PackageInfo, options: Options): string =
  pkgInfo.basicInfo.getPkgDest(options)

proc fullRequirements*(pkgInfo: PackageInfo): seq[PkgTuple] =
  ## Returns all requirements for a package (All top level + all task requirements)
  result = pkgInfo.requires
  for requirements in pkgInfo.taskRequires.values:
    result &= requirements

proc name*(pkgInfo: PackageInfo): string {.inline.} =
  pkgInfo.basicInfo.name

iterator lockedDepsFor*(allDeps: AllLockFileDeps, options: Options): (string, LockFileDep) =
  for task, deps in allDeps:
    if task in [noTask, options.task]:
      for name, dep in deps:
        yield (name, dep)

proc hasLockedDeps*(pkgInfo: PackageInfo): bool =
  ## Returns true if pkgInfo has any locked deps (including any tasks)
  # Check if any tasks have locked deps
  for deps in pkgInfo.lockedDeps.values:
    if deps.len > 0:
      return true

proc hasPackage*(deps: AllLockFileDeps, pkgName: string): bool =
  for deps in deps.values:
    if pkgName in deps:
      return true

proc `==`*(pkg1: PackageInfo, pkg2: PackageInfo): bool =
  pkg1.myPath == pkg2.myPath

proc hash*(x: PackageInfo): Hash =
  var h: Hash = 0
  h = h !& hash(x.myPath)
  result = !$h

proc getNameAndVersion*(pkgInfo: PackageInfo): string =
  &"{pkgInfo.basicInfo.name}@{pkgInfo.basicInfo.version}"

proc isNim*(name: string): bool =
  result = name == "nim" or name == "nimrod" or name == "compiler"

when isMainModule:
  import unittest

  test "toValidPackageName":
    check toValidPackageName("foo__bar") == "foo_bar"
    check toValidPackageName("jhbasdh!£$@%#^_&*_()qwe") == "jhbasdh_qwe"
