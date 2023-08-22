# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.
import parsecfg, streams, strutils, os, tables, uri

import common, cli

type
  Config* = object
    nimbleDir*: string
    chcp*: bool # Whether to change the code page in .cmd files on Win.
    packageLists*: Table[string, PackageList] ## Names -> packages.json files
    cloneUsingHttps*: bool # Whether to replace git:// for https://
    httpProxy*: Uri # Proxy for package list downloads.

  PackageList* = object
    name*: string
    urls*: seq[string]
    path*: string

proc initConfig(): Config =
  result.nimbleDir = getHomeDir() / ".nimble"
  result.httpProxy = initUri()
  result.chcp = true
  result.cloneUsingHttps = true
  result.packageLists["official"] = PackageList(name: "Official", urls: @[
    "https://raw.githubusercontent.com/nim-lang/packages/master/packages.json",
    "https://nim-lang.org/nimble/packages.json"
  ])

proc clear(pkgList: var PackageList) =
  pkgList.name = ""
  pkgList.urls = @[]
  pkgList.path = ""

proc addCurrentPkgList(config: var Config, currentPackageList: PackageList) =
  if currentPackageList.name.len > 0:
    config.packageLists[currentPackageList.name.normalize] = currentPackageList

proc parseConfig*(): Config =
  result = initConfig()
  var confFile = getConfigDir() / "nimble" / "nimble.ini"

  var f = newFileStream(confFile, fmRead)
  if f == nil:
    # Try the old deprecated babel.ini
    # TODO: This can be removed.
    confFile = getConfigDir() / "babel" / "babel.ini"
    f = newFileStream(confFile, fmRead)
    if f != nil:
      display("Warning", "Using deprecated config file at " & confFile,
              Warning, HighPriority)
  if f != nil:
    display("Reading", "config file at " & confFile, priority = LowPriority)
    var p: CfgParser
    open(p, f, confFile)
    var currentSection = ""
    var currentPackageList: PackageList
    while true:
      var e = next(p)
      case e.kind
      of cfgEof:
        if currentSection.len > 0:
          if currentPackageList.urls.len == 0 and currentPackageList.path == "":
            raise nimbleError("Package list '$1' requires either url or path" % currentPackageList.name)
          if currentPackageList.urls.len > 0 and currentPackageList.path != "":
            raise nimbleError("Attempted to specify `url` and `path` for the same package list '$1'" % currentPackageList.name)
          addCurrentPkgList(result, currentPackageList)
        break
      of cfgSectionStart:
        addCurrentPkgList(result, currentPackageList)
        currentSection = e.section
        case currentSection.normalize
        of "packagelist":
          currentPackageList.clear()
        else:
          raise nimbleError("Unable to parse config file:" &
                             " Unknown section: " & e.key)
      of cfgKeyValuePair, cfgOption:
        case e.key.normalize
        of "nimbledir":
          # Ensure we don't restore the deprecated nimble dir.
          if e.value != getHomeDir() / ".babel":
            result.nimbleDir = e.value
        of "chcp":
          result.chcp = parseBool(e.value)
        of "cloneusinghttps":
          result.cloneUsingHttps = parseBool(e.value)
        of "httpproxy":
          result.httpProxy = parseUri(e.value)
        of "name":
          case currentSection.normalize
          of "packagelist":
            currentPackageList.name = e.value
          else: assert false
        of "url":
          case currentSection.normalize
          of "packagelist":
            currentPackageList.urls.add(e.value)
          else: assert false
        of "path":
          case currentSection.normalize
          of "packagelist":
            if currentPackageList.path != "":
              raise nimbleError("Attempted to specify more than one `path` for the same package list.")
            else:
              currentPackageList.path = e.value
          else: assert false
        of "nimlibprefix":
          # Not relevant anymore but leaving in for legacy ini files
          discard
        else:
          raise nimbleError("Unable to parse config file:" &
                                     " Unknown key: " & e.key)
      of cfgError:
        raise nimbleError("Unable to parse config file: " & e.msg)
    close(p)
