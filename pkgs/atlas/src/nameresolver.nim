#
#           Atlas Package Cloner
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Resolves package names and turn them to URLs.

import std / [os, unicode, strutils, osproc, sequtils, options]
import context, osutils, packagesjson, gitops

export options

proc cloneUrlImpl(c: var AtlasContext,
                  url: PackageUrl,
                  dest: string;
                  cloneUsingHttps: bool):
                (CloneStatus, string) =
  ## Returns an error message on error or else "".
  assert not dest.contains("://")
  result = (OtherError, "")
  var modUrl = url
  if url.scheme == "git" and cloneUsingHttps:
    modUrl.scheme = "https"

  if url.scheme == "git":
    modUrl.scheme = "" # git doesn't recognize git://

  infoNow c, toRepo($modUrl), "Cloning URL: " & $modUrl

  var isGithub = false
  if modUrl.hostname == "github.com":
    if modUrl.path.endsWith("/"):
      # github + https + trailing url slash causes a
      # checkout/ls-remote to fail with Repository not found
      modUrl.path = modUrl.path[0 .. ^2]
    isGithub = true

  let (_, exitCode) = execCmdEx("git ls-remote --quiet --tags " & $modUrl)
  var xcode = exitCode
  if isGithub and exitCode != QuitSuccess:
    # retry multiple times to avoid annoying github timeouts:
    for i in 0..4:
      os.sleep(4000)
      infoNow c, toRepo($modUrl), "Check remote URL: " & $modUrl
      xcode = execCmdEx("git ls-remote --quiet --tags " & $modUrl)[1]
      if xcode == QuitSuccess: break

  if xcode == QuitSuccess:
    if gitops.clone(c, modUrl, dest):
      return (Ok, "")
    else:
      result = (OtherError, "exernal program failed: " & $GitClone)
  elif not isGithub:
    let (_, exitCode) = execCmdEx("hg identify " & $modUrl)
    if exitCode == QuitSuccess:
      let cmd = "hg clone " & $modUrl & " " & dest
      for i in 0..4:
        if execShellCmd(cmd) == 0: return (Ok, "")
        os.sleep(i*1_000+2_000)
      result = (OtherError, "exernal program failed: " & cmd)
    else:
      result = (NotFound, "Unable to identify url: " & $modUrl)
  else:
    result = (NotFound, "Unable to identify url: " & $modUrl)

proc cloneUrl*(c: var AtlasContext;
               url: PackageUrl,
               dest: string;
               cloneUsingHttps: bool): (CloneStatus, string) =
  when MockupRun:
    result = (Ok, "")
  else:
    result = cloneUrlImpl(c, url, dest, cloneUsingHttps)
    when ProduceTest:
      echo "cloned ", url, " into ", dest

proc updatePackages*(c: var AtlasContext) =
  if dirExists(c.workspace / DefaultPackagesDir):
    withDir(c, c.workspace / DefaultPackagesDir):
      gitPull(c, PackageRepo DefaultPackagesDir)
  else:
    withDir c, c.workspace:
      let (status, err) = cloneUrl(c, getUrl "https://github.com/nim-lang/packages", DefaultPackagesDir, false)
      if status != Ok:
        error c, PackageRepo(DefaultPackagesDir), err

proc fillPackageLookupTable(c: var AtlasContext) =
  if not c.hasPackageList:
    c.hasPackageList = true
    when not MockupRun:
      if not fileExists(c.workspace / DefaultPackagesDir / "packages.json"):
        updatePackages(c)
    let plist = getPackageInfos(when MockupRun: TestsDir else: c.workspace)
    debug c, toRepo("fillPackageLookupTable"), "initializing..."
    for entry in plist:
      let url = getUrl(entry.url)
      let pkg = Package(name: PackageName unicode.toLower entry.name,
                        repo: url.toRepo(),
                        url: url)
      c.urlMapping["name:" & pkg.name.string] = pkg

proc dependencyDir*(c: var AtlasContext; pkg: Package): PackageDir =
  template checkDir(dir: string) =
    if dir.len() > 0 and dirExists(dir):
      debug c, pkg, "dependencyDir: found: " & dir 
      return PackageDir dir
    else:
      debug c, pkg, "dependencyDir: not found: " & dir 
  
  debug c, pkg, "dependencyDir: check: pth: " & pkg.path.string & " cd: " & getCurrentDir() & " ws: " & c.workspace
  if pkg.exists:
    debug c, pkg, "dependencyDir: exists: " & pkg.path.string
    return PackageDir pkg.path.string.absolutePath
  if c.workspace.lastPathComponent == pkg.repo.string:
    debug c, pkg, "dependencyDir: workspace: " & c.workspace
    return PackageDir getCurrentDir()

  if pkg.path.string.len() > 0:
    checkDir pkg.path.string
    checkDir c.workspace / pkg.path.string
    checkDir c.depsDir / pkg.path.string
  
  checkDir c.workspace / pkg.repo.string
  checkDir c.depsDir / pkg.repo.string
  checkDir c.workspace / pkg.name.string
  checkDir c.depsDir / pkg.name.string
  result = PackageDir c.depsDir / pkg.repo.string
  trace c, pkg, "dependency not found using default"

proc findNimbleFile*(c: var AtlasContext; pkg: Package, depDir = PackageDir ""): Option[string] =
  when MockupRun:
    result = TestsDir / pkg.name.string & ".nimble"
    doAssert fileExists(result), "file does not exist " & result
  else:
    let dir = if depDir.string.len() == 0: dependencyDir(c, pkg).string
              else: depDir.string
    result = some dir / (pkg.name.string & ".nimble")
    debug  c, pkg, "findNimbleFile: searching: " & pkg.repo.string & " path: " & pkg.path.string & " dir: " & dir & " curr: " & result.get()
    if not fileExists(result.get()):
      debug  c, pkg, "findNimbleFile: not found: " & result.get()
      result = none[string]()
      for file in walkFiles(dir / "*.nimble"):
        if result.isNone:
          result = some file
          trace c, pkg, "nimble file found " & result.get()
        else:
          error c, pkg, "ambiguous .nimble file " & result.get()
          return none[string]()
    else:
      trace c, pkg, "nimble file found " & result.get()
      discard

proc resolvePackageUrl(c: var AtlasContext; url: string, checkOverrides = true): Package =
  result = Package(url: getUrl(url),
                   name: url.toRepo().PackageName,
                   repo: url.toRepo())
  
  debug c, result, "resolvePackageUrl: search: " & url

  let isFile = result.url.scheme == "file"
  var isUrlOverriden = false
  if not isFile and checkOverrides and UsesOverrides in c.flags:
    let url = c.overrides.substitute($result.url)
    if url.len > 0:
      warn c, result, "resolvePackageUrl: url override found: " & $url
      result.url = url.getUrl()
      isUrlOverriden = true

  let namePkg = c.urlMapping.getOrDefault("name:" & result.name.string, nil)
  let repoPkg = c.urlMapping.getOrDefault("repo:" & result.repo.string, nil)

  if not namePkg.isNil:
    debug c, result, "resolvePackageUrl: found by name: " & $result.name.string
    if namePkg.url != result.url and isUrlOverriden:
      namePkg.url = result.url # update package url to match
      result = namePkg
    elif namePkg.url != result.url:
      # package conflicts
      # change package repo to `repo.user.host`
      let purl = result.url
      let host = purl.hostname
      let org = purl.path.parentDir.lastPathPart
      let rname = purl.path.lastPathPart
      let pname = [rname, org, host].join(".") 
      warn c, result,
              "conflicting url's for package; renaming package: " &
                result.name.string & " to " & pname
      result.repo = PackageRepo pname
      c.urlMapping["name:" & result.name.string] = result
    else:
      result = namePkg
  elif not repoPkg.isNil:
    debug c, result, "resolvePackageUrl: found by repo: " & $result.repo.string
    result = repoPkg
  else:
    # package doesn't exit and doesn't conflict
    # set the url with package name as url name
    c.urlMapping["repo:" & result.name.string] = result
    trace c, result, "resolvePackageUrl: not found; set pkg: " & $result.repo.string
  
  if result.url.scheme == "file":
    result.path = PackageDir result.url.hostname & result.url.path
    trace c, result, "resolvePackageUrl: setting manual path: " & $result.path.string

proc resolvePackageName(c: var AtlasContext; name: string): Package =
  result = Package(name: PackageName name,
                   repo: PackageRepo name)
                   
  # the project name can be overwritten too!
  if UsesOverrides in c.flags:
    let name = c.overrides.substitute(name)
    if name.len > 0:
      if name.isUrl():
        return c.resolvePackageUrl(name, checkOverrides=false)

  # echo "URL MAP: ", repr c.urlMapping.keys().toSeq()
  let namePkg = c.urlMapping.getOrDefault("name:" & result.name.string, nil)
  let repoPkg = c.urlMapping.getOrDefault("repo:" & result.name.string, nil)

  debug c, result, "resolvePackageName: searching for package name: " & result.name.string
  if not namePkg.isNil:
    # great, found package!
    debug c, result, "resolvePackageName: found!"
    result = namePkg
    result.inPackages = true
  elif not repoPkg.isNil:
    # check if rawHandle is a package repo name
    debug c, result, "resolvePackageName: found by repo!"
    result = repoPkg
    result.inPackages = true
  else:
    info c, result, "could not resolve by name or repo; searching GitHub"
    let url = c.getUrlFromGithub(name)
    if url.len == 0:
      error c, result, "package not found by github search"
    else:
      result.url = getUrl url

  if UsesOverrides in c.flags:
    let newUrl = c.overrides.substitute($result.url)
    if newUrl.len > 0:
      trace c, result, "resolvePackageName: not url: UsesOverrides: " & $newUrl
      result.url = getUrl newUrl

proc resolvePackage*(c: var AtlasContext; rawHandle: string): Package =
  ## Takes a raw handle which can be a name, a repo name, or a url
  ## and resolves it into a package. If not found it will create
  ## a new one.
  ## 
  ## Note that Package should be unique globally. This happens
  ## by updating the packages list when new packages are added or
  ## loaded from a packages.json.
  ## 
  result.new()

  fillPackageLookupTable(c)

  trace c, toRepo(rawHandle), "resolving package"

  if rawHandle.isUrl():
    result = c.resolvePackageUrl(rawHandle)
  else:
    result = c.resolvePackageName(unicode.toLower(rawHandle))
  
  result.path = dependencyDir(c, result)
  let res = c.findNimbleFile(result, result.path)
  if res.isSome:
    let nimble = PackageNimble res.get()
    result.exists = true
    result.nimble = nimble
    # the nimble package name is <name>.nimble
    result.name = PackageName nimble.string.splitFile().name
    debug c, result, "resolvePackageName: nimble: found: " & $result
  else:
    debug c, result, "resolvePackageName: nimble: not found: " & $result
  

proc resolveNimble*(c: var AtlasContext; pkg: Package) =
  ## Try to resolve the nimble file for the given package.
  ## 
  ## This should be done after cloning a new repo. 
  ## 

  if pkg.exists:
    return

  pkg.path = dependencyDir(c, pkg)
  let res = c.findNimbleFile(pkg)
  if res.isSome:
    let nimble = PackageNimble res.get()
    # let path = PackageDir res.get().parentDir()
    pkg.exists = true
    pkg.nimble = nimble
    info c, pkg, "resolvePackageName: nimble: found: " & $pkg
  else:
    info c, pkg, "resolvePackageName: nimble: not found: " & $pkg

