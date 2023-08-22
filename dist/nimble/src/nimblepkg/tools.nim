# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.
#
# Various miscellaneous utility functions reside here.
import osproc, pegs, strutils, os, uri, sets, json, parseutils, strformat,
       sequtils

from net import SslCVerifyMode, newContext, SslContext

import version, cli, common, packageinfotypes, options, sha1hashes
from compiler/nimblecmd import getPathVersionChecksum

proc extractBin(cmd: string): string =
  if cmd[0] == '"':
    return cmd.captureBetween('"')
  else:
    return cmd.split(' ')[0]

proc doCmd*(cmd: string) =
  let
    bin = extractBin(cmd)
    isNim = bin.extractFilename().startsWith("nim")
  if findExe(bin) == "":
    raise nimbleError("'" & bin & "' not in PATH.")

  # To keep output in sequence
  stdout.flushFile()
  stderr.flushFile()

  if isNim:
    # Show no command line and --hints:off output by default for calls
    # to Nim, command line and standard output with --verbose.
    display("Executing", cmd, priority = MediumPriority)
    let exitCode = execCmd(cmd)
    if exitCode != QuitSuccess:
      raise nimbleError(
        "Execution failed with exit code $1\nCommand: $2" %
        [$exitCode, cmd])
  else:
    displayDebug("Executing", cmd)
    let (output, exitCode) = execCmdEx(cmd)
    displayDebug("Output", output)
    if exitCode != QuitSuccess:
      raise nimbleError(
        "Execution failed with exit code $1\nCommand: $2\nOutput: $3" %
        [$exitCode, cmd, output])

proc doCmdEx*(cmd: string): ProcessOutput =
  displayDebug("Executing", cmd)
  let bin = extractBin(cmd)
  if findExe(bin) == "":
    raise nimbleError("'" & bin & "' not in PATH.")
  return execCmdEx(cmd)

proc tryDoCmdExErrorMessage*(cmd, output: string, exitCode: int): string =
  &"Execution of '{cmd}' failed with an exit code {exitCode}.\n" &
  &"Details: {output}"

proc tryDoCmdEx*(cmd: string): string {.discardable.} =
  let (output, exitCode) = doCmdEx(cmd)
  if exitCode != QuitSuccess:
    raise nimbleError(tryDoCmdExErrorMessage(cmd, output, exitCode))
  return output

proc getNimrodVersion*(options: Options): Version =
  let vOutput = doCmdEx(getNimBin(options).quoteShell & " -v").output
  var matches: array[0..MaxSubpatterns, string]
  if vOutput.find(peg"'Version'\s{(\d+\.)+\d+}", matches) == -1:
    raise nimbleError("Couldn't find Nim version.")
  newVersion(matches[0])

proc samePaths*(p1, p2: string): bool =
  ## Normalizes path (by adding a trailing slash) and compares.
  var cp1 = if not p1.endsWith("/"): p1 & "/" else: p1
  var cp2 = if not p2.endsWith("/"): p2 & "/" else: p2
  cp1 = cp1.replace('/', DirSep).replace('\\', DirSep)
  cp2 = cp2.replace('/', DirSep).replace('\\', DirSep)

  return cmpPaths(cp1, cp2) == 0

proc changeRoot*(origRoot, newRoot, path: string): string =
  ## origRoot: /home/dom/
  ## newRoot:  /home/test/
  ## path:     /home/dom/bar/blah/2/foo.txt
  ## Return value -> /home/test/bar/blah/2/foo.txt

  ## The additional check of `path.samePaths(origRoot)` is necessary to prevent
  ## a regression, where by ending the `srcDir` defintion in a nimble file in a
  ## trailing separator would cause the `path.startsWith(origRoot)` evaluation to
  ## fail because of the value of `origRoot` would be longer than `path` due to
  ## the trailing separator. This would cause this method to throw during package
  ## installation.
  if path.startsWith(origRoot) or path.samePaths(origRoot):
    return newRoot / path.substr(origRoot.len, path.len-1)
  else:
    raise nimbleError(
      "Cannot change root of path: Path does not begin with original root.")

proc copyFileD*(fro, to: string): string =
  ## Returns the destination (``to``).
  display("Copying", "file $# to $#" % [fro, to], priority = LowPriority)
  copyFileWithPermissions(fro, to)
  result = to

proc copyDirD*(fro, to: string): seq[string] =
  ## Returns the filenames of the files in the directory that were copied.
  result = @[]
  display("Copying", "directory $# to $#" % [fro, to], priority = LowPriority)
  for path in walkDirRec(fro):
    createDir(changeRoot(fro, to, path.splitFile.dir))
    result.add copyFileD(path, changeRoot(fro, to, path))

proc createDirD*(dir: string) =
  display("Creating", "directory $#" % dir, priority = LowPriority)
  createDir(dir)

proc getDownloadDirName*(uri: string, verRange: VersionRange,
                         vcsRevision: Sha1Hash): string =
  ## Creates a directory name based on the specified ``uri`` (url)
  let puri = parseUri(uri)
  for i in puri.hostname:
    case i
    of strutils.Letters, strutils.Digits:
      result.add i
    else: discard
  result.add "_"
  for i in puri.path:
    case i
    of strutils.Letters, strutils.Digits:
      result.add i
    else: discard

  let verSimple = getSimpleString(verRange)
  if verSimple != "":
    result.add "_"
    result.add verSimple
  
  if vcsRevision != notSetSha1Hash:
    result.add "_"
    result.add $vcsRevision

proc incl*(s: var HashSet[string], v: seq[string] | HashSet[string]) =
  for i in v:
    s.incl i

when not declared(json.contains):
  proc contains*(j: JsonNode, elem: JsonNode): bool =
    for i in j:
      if i == elem:
        return true

proc contains*(j: JsonNode, elem: tuple[key: string, val: JsonNode]): bool =
  for key, val in pairs(j):
    if key == elem.key and val == elem.val:
      return true

proc getNimbleTempDir*(): string =
  ## Returns a path to a temporary directory.
  ##
  ## The returned path will be the same for the duration of the process but
  ## different for different runs of it. You have to make sure to create it
  ## first. In release builds the directory will be removed when nimble finishes
  ## its work.
  result = getTempDir() / "nimble_" & $getCurrentProcessId()

proc getNimbleUserTempDir*(): string =
  ## Returns a path to a temporary directory.
  ##
  ## The returned path will be the same for the duration of the process but
  ## different for different runs of it. You have to make sure to create it
  ## first. In release builds the directory will be removed when nimble finishes
  ## its work.
  var tmpdir: string
  if existsEnv("TMPDIR") and existsEnv("USER"):
    tmpdir = joinPath(getEnv("TMPDIR"), getEnv("USER"))
  else:
    tmpdir = getTempDir()
  return tmpdir

proc isEmptyDir*(dir: string): bool =
  toSeq(walkDirRec(dir)).len == 0

proc getNameVersionChecksum*(pkgpath: string): PackageBasicInfo =
  ## Splits ``pkgpath`` in the format
  ## ``/home/user/.nimble/pkgs/package-0.1-febadeaea2345e777f0f6f8433f7f0a52edd5d1b``
  ## into ``("packagea", "0.1", "febadeaea2345e777f0f6f8433f7f0a52edd5d1b")``
  ##
  ## Also works for file paths like:
  ## ``/home/user/.nimble/pkgs/package-0.1-febadeaea2345e777f0f6f8433f7f0a52edd5d1b/package.nimble``

  if pkgPath.splitFile.ext in [".nimble", ".babel"]:
    return getNameVersionChecksum(pkgPath.splitPath.head)

  let (name, version, checksum) = getPathVersionChecksum(pkgPath.splitPath.tail)
  let sha1Checksum = 
    try:
      initSha1Hash(checksum)
    except InvalidSha1HashError:
      notSetSha1Hash

  return (name, newVersion(version), sha1Checksum)

proc removePackageDir*(files: seq[string], dir: string, reportSuccess = false) =
  for file in files:
    removeFile(dir / file)

  if dir.isEmptyDir():
    removeDir(dir)
    if reportSuccess:
      displaySuccess(&"The directory \"{dir}\" has been removed.",
                     MediumPriority)
  else:
    displayWarning(
      &"Cannot completely remove the directory \"{dir}\".\n" &
       "Files not installed by Nimble are present.")

proc newSSLContext*(disabled: bool): SslContext =
  var sslVerifyMode = CVerifyPeer
  if disabled:
    display("Warning:", "disabling SSL certificate checking", Warning)
    sslVerifyMode = CVerifyNone
  return newContext(verifyMode = sslVerifyMode)

when isMainModule:
  import unittest

  suite "getNameVersionCheksum":
    test "directory names without sha1 hashes":
      check getNameVersionChecksum(
        "/home/user/.nimble/libs/packagea-0.1") ==
        ("packagea", newVersion("0.1"), notSetSha1Hash)

      check getNameVersionChecksum(
        "/home/user/.nimble/libs/package-a-0.1") ==
        ("package-a", newVersion("0.1"), notSetSha1Hash)

      check getNameVersionChecksum(
        "/home/user/.nimble/libs/package-a-0.1/package.nimble") ==
        ("package-a", newVersion("0.1"), notSetSha1Hash)

      check getNameVersionChecksum(
        "/home/user/.nimble/libs/package-#head") ==
        ("package", newVersion("#head"), notSetSha1Hash)

      check getNameVersionChecksum(
        "/home/user/.nimble/libs/package-#branch-with-dashes") ==
        ("package", newVersion("#branch-with-dashes"), notSetSha1Hash)

      # readPackageInfo (and possibly more) depends on this not raising.
      check getNameVersionChecksum(
        "/home/user/.nimble/libs/package") ==
        ("package", newVersion(""), notSetSha1Hash)

    test "directory names with sha1 hashes":
      check getNameVersionChecksum(
        "/home/user/.nimble/libs/packagea-0.1-" &
         "9e6df089c5ee3d912006b2d1c016eb8fa7dcde82") ==
        ("packagea", newVersion("0.1"),
         "9e6df089c5ee3d912006b2d1c016eb8fa7dcde82".initSha1Hash)

      check getNameVersionChecksum(
        "/home/user/.nimble/libs/package-a-0.1-" &
         "2f11b50a3d1933f9f8972bd09bc3325c38bc11d6") ==
        ("package-a", newVersion("0.1"),
         "2f11b50a3d1933f9f8972bd09bc3325c38bc11d6".initSha1Hash)

      check getNameVersionChecksum(
        "/home/user/.nimble/libs/package-a-0.1-" &
         "43e3b1138312656310e93ffcfdd866b2dcce3b35/package.nimble") ==
        ("package-a", newVersion("0.1"),
         "43e3b1138312656310e93ffcfdd866b2dcce3b35".initSha1Hash)

      check getNameVersionChecksum(
        "/home/user/.nimble/libs/package-#head-" &
         "efba335dccf2631d7ac2740109142b92beb3b465") ==
        ("package", newVersion("#head"),
         "efba335dccf2631d7ac2740109142b92beb3b465".initSha1Hash)

      check getNameVersionChecksum(
        "/home/user/.nimble/libs/package-#branch-with-dashes-" &
         "8f995e59d6fc1012b3c1509fcb0ef0a75cb3610c") ==
        ("package", newVersion("#branch-with-dashes"),
         "8f995e59d6fc1012b3c1509fcb0ef0a75cb3610c".initSha1Hash)

      check getNameVersionChecksum(
        "/home/user/.nimble/libs/package-" &
         "b12e18db49fc60df117e5d8a289c4c2050a272dd") ==
        ("package", newVersion(""),
         "b12e18db49fc60df117e5d8a289c4c2050a272dd".initSha1Hash)
