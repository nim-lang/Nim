#
#           Atlas Package Cloner
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Resolves package names and turn them to URLs.

import std / [os, unicode]
import context, osutils, packagesjson, gitops

proc cloneUrl*(c: var AtlasContext;
               url: PackageUrl,
               dest: string;
               cloneUsingHttps: bool): (CloneStatus, string) =
  when MockupRun:
    result = (Ok, "")
  else:
    result = osutils.cloneUrl(url, dest, cloneUsingHttps)
    when ProduceTest:
      echo "cloned ", url, " into ", dest

proc updatePackages*(c: var AtlasContext) =
  if dirExists(c.workspace / PackagesDir):
    withDir(c, c.workspace / PackagesDir):
      gitPull(c, PackageName PackagesDir)
  else:
    withDir c, c.workspace:
      let (status, err) = cloneUrl(c, getUrl "https://github.com/nim-lang/packages", PackagesDir, false)
      if status != Ok:
        error c, PackageName(PackagesDir), err

proc fillPackageLookupTable(c: var AtlasContext) =
  if not c.hasPackageList:
    c.hasPackageList = true
    when not MockupRun:
      if not fileExists(c.workspace / PackagesDir / "packages.json"):
        updatePackages(c)
    let plist = getPackages(when MockupRun: TestsDir else: c.workspace)
    for entry in plist:
      c.p[unicode.toLower entry.name] = entry.url

proc resolveUrl*(c: var AtlasContext; p: string): PackageUrl =
  proc lookup(c: var AtlasContext; p: string): string =
    if p.isUrl:
      if UsesOverrides in c.flags:
        result = c.overrides.substitute(p)
        if result.len > 0: return result
      result = p
    else:
      # either the project name or the URL can be overwritten!
      if UsesOverrides in c.flags:
        result = c.overrides.substitute(p)
        if result.len > 0: return result

      fillPackageLookupTable(c)
      result = c.p.getOrDefault(unicode.toLower p)

      if result.len == 0:
        result = getUrlFromGithub(p)
        if result.len == 0:
          inc c.errors

      if UsesOverrides in c.flags:
        let newUrl = c.overrides.substitute(result)
        if newUrl.len > 0: return newUrl

  let urlstr = lookup(c, p)
  result = urlstr.getUrl()
