# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

import json, sets, os, hashes

import options, version, download, jsonhelpers, nimbledatafile, sha1hashes,
       packageinfotypes, packageinfo, packageparser

type
  ReverseDependencyKind* = enum
    rdkInstalled,
    rdkDevelop,

  ReverseDependency* = object
    ## Represents a reverse dependency info containing name, version and
    ## checksum for the installed packages or the path to the package directory
    ## for the reverse dependencies.
    case kind*: ReverseDependencyKind
    of rdkInstalled:
      pkgInfo*: PackageBasicInfo
    of rdkDevelop:
      pkgPath*: string

proc hash*(revDep: ReverseDependency): Hash =
  case revDep.kind
  of rdkInstalled:
    result = revDep.pkgInfo.getCacheDir.hash
  of rdkDevelop:
    result = revDep.pkgPath.hash

proc `==`*(lhs, rhs: ReverseDependency): bool =
  if lhs.kind != rhs.kind:
    return false
  case lhs.kind:
  of rdkInstalled:
    return lhs.pkgInfo == rhs.pkgInfo
  of rdkDevelop:
    return lhs.pkgPath == rhs.pkgPath

proc `$`*(revDep: ReverseDependency): string =
  case revDep.kind
  of rdkInstalled:
    result = revDep.pkgInfo.getCacheDir
  of rdkDevelop:
    result = revDep.pkgPath

proc addRevDep*(nimbleData: JsonNode, dep: PackageBasicInfo,
                pkg: PackageInfo) =
  # Add a record which specifies that `pkg` has a dependency on `dep`, i.e.
  # the reverse dependency of `dep` is `pkg`.

  let dependencies = nimbleData.addIfNotExist(
    $ndjkRevDep,
    dep.name,
    $dep.version,
    $dep.checksum,
    newJArray())

  var dependency: JsonNode
  if not pkg.isLink:
    dependency = %{
      $ndjkRevDepName: %pkg.basicInfo.name,
      $ndjkRevDepVersion: %pkg.basicInfo.version,
      $ndjkRevDepChecksum: %pkg.basicInfo.checksum}
  else:
    dependency = %{ $ndjkRevDepPath: %pkg.getNimbleFileDir().absolutePath }

  if dependency notin dependencies:
    dependencies.add(dependency)

proc removeRevDep*(nimbleData: JsonNode, pkg: PackageInfo) =
  ## Removes ``pkg`` from the reverse dependencies of every package.

  assert(not pkg.isMinimal)

  proc remove(pkg: PackageInfo, depTup: PkgTuple, thisDep: JsonNode) =
    for version, revDepsForVersion in thisDep:
      if version.newVersion in depTup.ver:
        for checksum, revDepsForChecksum in revDepsForVersion:
          var newVal = newJArray()
          for rd in revDepsForChecksum:
            # If the reverse dependency is different than the package which we
            # currently deleting, it will be kept.
            if rd.hasKey($ndjkRevDepPath):
              # This is a develop mode reverse dependency.
              if rd[$ndjkRevDepPath].str != pkg.getNimbleFileDir:
                # It is compared by its directory path.
                newVal.add rd
            elif rd[$ndjkRevDepChecksum].str != $pkg.basicInfo.checksum:
              # Installed dependencies are compared by checksum.
              newVal.add rd
          revDepsForVersion[checksum] = newVal

  let reverseDependencies = nimbleData[$ndjkRevDep]

  for depTup in pkg.requires:
    if depTup.name.isURL():
      # We sadly must go through everything in this case...
      for key, val in reverseDependencies:
        remove(pkg, depTup, val)
    else:
      let thisDep = nimbleData{$ndjkRevDep, depTup.name}
      if thisDep.isNil: continue
      remove(pkg, depTup, thisDep)

  nimbleData[$ndjkRevDep] = cleanUpEmptyObjects(reverseDependencies)

proc getRevDeps*(nimbleData: JsonNode, pkg: ReverseDependency):
    HashSet[ReverseDependency] =
  ## Returns a list of *currently installed* or *develop mode* reverse
  ## dependencies for `pkg`.

  if pkg.kind == rdkDevelop:
    return

  let reverseDependencies = nimbleData[$ndjkRevDep]{
    pkg.pkgInfo.name}{$pkg.pkgInfo.version}{$pkg.pkgInfo.checksum}

  if reverseDependencies.isNil:
    return

  for revDep in reverseDependencies:
    if revDep.hasKey($ndjkRevDepPath):
      # This is a develop mode package.
      let path = revDep[$ndjkRevDepPath].str
      result.incl ReverseDependency(kind: rdkDevelop, pkgPath: path)
    else:
      # This is an installed package.
      let pkgBasicInfo =
        (name: revDep[$ndjkRevDepName].str,
         version: newVersion(revDep[$ndjkRevDepVersion].str),
         checksum: revDep[$ndjkRevDepChecksum].str.initSha1Hash)
      result.incl ReverseDependency(kind: rdkInstalled, pkgInfo: pkgBasicInfo)

proc toPkgInfo*(revDep: ReverseDependency, options: Options): PackageInfo =
  case revDep.kind
  of rdkInstalled:
    let pkgDir = revDep.pkgInfo.getPkgDest(options)
    result = getPkgInfo(pkgDir, options)
  of rdkDevelop:
    result = getPkgInfo(revDep.pkgPath, options)

proc toRevDep*(pkg: PackageInfo): ReverseDependency =
  if not pkg.isLink:
    result = ReverseDependency(
      kind: rdkInstalled,
      pkgInfo: pkg.basicInfo)
  else:
    result = ReverseDependency(
      kind: rdkDevelop,
      pkgPath: pkg.getNimbleFileDir)

proc getAllRevDeps*(nimbleData: JsonNode, pkg: ReverseDependency,
                    result: var HashSet[ReverseDependency]) =
  result.incl pkg
  let revDeps = getRevDeps(nimbleData, pkg)
  for revDep in revDeps:
    if revDep in result: continue
    getAllRevDeps(nimbleData, revDep, result)

when isMainModule:
  import unittest, sequtils

  type
    RequiresSeq = seq[tuple[name, versionRange: string]]

  proc initMetaData: PackageMetaData =
    result = PackageMetaData(
      vcsRevision: notSetSha1Hash)

  proc parseRequires(requires: RequiresSeq): seq[PkgTuple] =
    requires.mapIt((it.name, it.versionRange.parseVersionRange))

  proc initPackageInfo(path: string, requires: RequiresSeq = @[]): PackageInfo =
    result = PackageInfo(
      myPath: path,
      requires: requires.parseRequires,
      metaData: initMetaData(),
      isLink: true)

  proc initPackageInfo(name, version, checksum: string,
                       requires: RequiresSeq = @[]): PackageInfo =
    result = PackageInfo(
      basicInfo: (name, version.newVersion, checksum.initSha1Hash),
      requires: requires.parseRequires,
      metaData: initMetaData(),
      isLink: false)

  let
    nimforum1 = initPackageInfo(
      "nimforum", "0.1.0", "46a96c3f2b0ecb3d3f7bd71e12200ed401e9b9f2",
      @[("jester", "0.1.0"), ("captcha", "1.0.0"), ("auth", "2.0.0")])
    nimforum1RevDep = nimforum1.toRevDep

    nimforum2 = initPackageInfo(
      "nimforum", "0.2.0", "b60044137cea185f287346ebeab6b3e0895bda4d")
    nimforum2RevDep = nimforum2.toRevDep

    play = initPackageInfo(
      "play", "2.0.1", "8a54cca572977ed0cc73b9bf783e9dfa6b6f2bf9")

    nimforumDevelop = initPackageInfo(
      "/some/absolute/system/path/nimforum/nimforum.nimble",
      @[("captcha", "1.0.0")])
    nimforumDevelopRevDep = nimforumDevelop.toRevDep

    jester = initPackageInfo(
      "jester", "0.1.0", "1b629f98b23614df292f176a1681fa439dcc05e2")

    jester2 = initPackageInfo(
      "jester", "0.1.0", "deff1d836528db4fd128932ebd48e568e52b7bb4")

    captcha = initPackageInfo(
      "captcha", "1.0.0", "ce128561b06dd106a83638ad415a2a52548f388e")
    captchaRevDep = captcha.toRevDep
    
    auth = initPackageInfo(
      "auth", "2.0.0", "c81545df8a559e3da7d38d125e0eaf2b4478cd01")
    authRevDep = auth.toRevDep

  suite "reverse dependencies":
    setup:
      var nimbleData = newNimbleDataNode()
      nimbleData.addRevDep(jester.basicInfo, nimforum1)
      nimbleData.addRevDep(jester2.basicInfo, play)
      nimbleData.addRevDep(captcha.basicInfo, nimforum1)
      nimbleData.addRevDep(captcha.basicInfo, nimforum2)
      nimbleData.addRevDep(captcha.basicInfo, nimforumDevelop)
      nimbleData.addRevDep(auth.basicInfo, nimforum1)
      nimbleData.addRevDep(auth.basicInfo, nimforum2)
      nimbleData.addRevDep(auth.basicInfo, captcha)

    test "addRevDep":
      let expectedResult = """{
          "version": 1,
          "reverseDeps": {
            "jester": {
              "0.1.0": {
                "1b629f98b23614df292f176a1681fa439dcc05e2": [
                  {
                    "name": "nimforum",
                    "version": "0.1.0",
                    "checksum": "46a96c3f2b0ecb3d3f7bd71e12200ed401e9b9f2"
                  }
                ],
                "deff1d836528db4fd128932ebd48e568e52b7bb4": [
                  {
                    "name": "play",
                    "version": "2.0.1",
                    "checksum": "8a54cca572977ed0cc73b9bf783e9dfa6b6f2bf9"
                  }
                ]
              }
            },
            "captcha": {
              "1.0.0": {
                "ce128561b06dd106a83638ad415a2a52548f388e": [
                  {
                    "name": "nimforum",
                    "version": "0.1.0",
                    "checksum": "46a96c3f2b0ecb3d3f7bd71e12200ed401e9b9f2"
                  },
                  {
                    "name": "nimforum",
                    "version": "0.2.0",
                    "checksum": "b60044137cea185f287346ebeab6b3e0895bda4d"
                  },
                  {
                    "path": "/some/absolute/system/path/nimforum"
                  }
                ]
              }
            },
            "auth": {
              "2.0.0": {
                "c81545df8a559e3da7d38d125e0eaf2b4478cd01": [
                  {
                    "name": "nimforum",
                    "version": "0.1.0",
                    "checksum": "46a96c3f2b0ecb3d3f7bd71e12200ed401e9b9f2"
                  },
                  {
                    "name": "nimforum",
                    "version": "0.2.0",
                    "checksum": "b60044137cea185f287346ebeab6b3e0895bda4d"
                  },
                  {
                    "name": "captcha",
                    "version": "1.0.0",
                    "checksum": "ce128561b06dd106a83638ad415a2a52548f388e"
                  }
                ]
              }
            }
          }
        }""".parseJson()

      check nimbleData == expectedResult

    test "removeRevDep":
      let expectedResult = """{
          "version": 1,
          "reverseDeps": {
            "jester": {
              "0.1.0": {
                "deff1d836528db4fd128932ebd48e568e52b7bb4": [
                  {
                    "name": "play",
                    "version": "2.0.1",
                    "checksum": "8a54cca572977ed0cc73b9bf783e9dfa6b6f2bf9"
                  }
                ]
              }
            },
            "captcha": {
              "1.0.0": {
                "ce128561b06dd106a83638ad415a2a52548f388e": [
                  {
                    "name": "nimforum",
                    "version": "0.2.0",
                    "checksum": "b60044137cea185f287346ebeab6b3e0895bda4d"
                  }
                ]
              }
            },
            "auth": {
              "2.0.0": {
                "c81545df8a559e3da7d38d125e0eaf2b4478cd01": [
                  {
                    "name": "nimforum",
                    "version": "0.2.0",
                    "checksum": "b60044137cea185f287346ebeab6b3e0895bda4d"
                  },
                  {
                    "name": "captcha",
                    "version": "1.0.0",
                    "checksum": "ce128561b06dd106a83638ad415a2a52548f388e"
                  }
                ]
              }
            }
          }
        }""".parseJson()

      nimbleData.removeRevDep(nimforum1)
      nimbleData.removeRevDep(nimforumDevelop)
      check nimbleData == expectedResult

    test "getRevDeps":
      check nimbleData.getRevDeps(nimforumDevelopRevDep) ==
            HashSet[ReverseDependency]()
      check nimbleData.getRevDeps(captchaRevDep) ==
            [nimforum1RevDep, nimforum2RevDep, nimforumDevelopRevDep].toHashSet

    test "getAllRevDeps":
      var revDeps: HashSet[ReverseDependency]
      nimbleData.getAllRevDeps(authRevDep, revDeps)
      check revDeps == [authRevDep, nimforum1RevDep, nimforum2RevDep,
                        nimforumDevelopRevDep, captchaRevDep].toHashSet
