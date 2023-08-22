# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

{.used.}

import sequtils, strutils, strformat, os, osproc, sugar, unittest, macros
import ../dist/checksums/src/checksums/sha1

from nimblepkg/common import cd, nimblePackagesDirName, ProcessOutput
from nimblepkg/developfile import developFileVersion

const
  stringNotFound* = -1
  pkgAUrl* = "https://github.com/nimble-test/packagea.git"
  pkgBUrl* = "https://github.com/nimble-test/packageb.git"
  pkgBinUrl* = "https://github.com/nimble-test/packagebin.git"
  pkgBin2Url* = "https://github.com/nimble-test/packagebin2.git"
  pkgMultiUrl = "https://github.com/nimble-test/multi"
  pkgMultiAlphaUrl* = &"{pkgMultiUrl}?subdir=alpha"
  pkgMultiBetaUrl* = &"{pkgMultiUrl}?subdir=beta"

let
  rootDir = getCurrentDir().parentDir
  nimblePath* = rootDir / "src" / addFileExt("nimble", ExeExt)
  nimbleCompilePath = rootDir / "src" / "nimble.nim"
  installDir* = rootDir / "tests" / "nimbleDir"
  buildTests* = rootDir / "buildTests"
  pkgsDir* = installDir / nimblePackagesDirName

proc execNimble*(args: varargs[string]): ProcessOutput =
  var quotedArgs = @args
  quotedArgs.insert("--nimbleDir:" & installDir)
  quotedArgs.insert(nimblePath)
  quotedArgs = quotedArgs.map((x: string) => x.quoteShell)

  let path {.used.} = getCurrentDir().parentDir() / "src"

  var cmd =
    when not defined(windows):
      "PATH=" & path & ":$PATH " & quotedArgs.join(" ")
    else:
      quotedArgs.join(" ")
  when defined(macosx):
    # TODO: Yeah, this is really specific to my machine but for my own sanity...
    cmd = "DYLD_LIBRARY_PATH=/usr/local/opt/openssl@1.1/lib " & cmd

  result = execCmdEx(cmd)
  checkpoint(cmd)
  checkpoint(result.output)

proc execNimbleYes*(args: varargs[string]): ProcessOutput =
  # issue #6314
  execNimble(@args & "-y")

proc execBin*(name: string): tuple[output: string, exitCode: int] =
  var
    cmd = installDir / "bin" / name

  when defined(windows):
    cmd = "cmd /c " & cmd & ".cmd"

  result = execCmdEx(cmd)

template verify*(res: (string, int)) =
  let r = res
  checkpoint r[0]
  check r[1] == QuitSuccess

proc processOutput*(output: string): seq[string] =
  output.strip.splitLines().filter(
    (x: string) => (
      x.len > 0 and
      "Using env var NIM_LIB_PREFIX" notin x
    )
  )

macro defineInLinesProc(procName, extraLine: untyped): untyped  =
  var LinesType = quote do: seq[string]
  if extraLine[0].kind != nnkDiscardStmt:
    LinesType = newTree(nnkVarTy, LinesType)

  let linesParam = ident("lines")
  let linesLoopCounter = ident("i")

  result = quote do:
    proc `procName`*(`linesParam`: `LinesType`, msg: string): bool =
      let msgLines = msg.splitLines
      for msgLine in msgLines:
        let msgLine = msgLine.normalize
        var msgLineFound = false
        for `linesLoopCounter`, line in `linesParam`:
          if msgLine in line.normalize:
            msgLineFound = true
            `extraLine`
            break
        if not msgLineFound:
          return false
      return true

defineInLinesProc(inLines): discard
defineInLinesProc(inLinesOrdered): lines = lines[i + 1 .. ^1]

proc hasLineStartingWith*(lines: seq[string], prefix: string): bool =
  for line in lines:
    if line.strip(trailing = false).startsWith(prefix):
      return true
  return false

proc getPackageDir*(pkgCacheDir, pkgDirPrefix: string, fullPath = true): string =
  for kind, dir in walkDir(pkgCacheDir):
    if kind != pcDir or not dir.startsWith(pkgCacheDir / pkgDirPrefix):
      continue
    let pkgChecksumStartIndex = dir.rfind('-')
    if pkgChecksumStartIndex == -1:
      continue
    let pkgChecksum = dir[pkgChecksumStartIndex + 1 .. ^1]
    if pkgChecksum.isValidSha1Hash():
      return if fullPath: dir else: dir.splitPath.tail
  return ""

proc packageDirExists*(pkgCacheDir, pkgDirPrefix: string): bool =
  getPackageDir(pkgCacheDir, pkgDirPrefix).len > 0

proc safeMoveFile(src, dest: string) =
  try:
    moveFile(src, dest)
  except OSError:
    copyFile(src, dest)
    removeFile(src)

proc uninstallDeps*() =
  ## Uninstalls all installed dependencies.
  ## Useful for cleaning up after a test case
  let (output, _) = execNimble("list", "-i")
  for line in output.splitLines:
    let package = line.split("  ")[0]
    if package != "":
      discard execNimbleYes("uninstall", "-i", package)


template testRefresh*(body: untyped) =
  # Backup current config
  let configFile {.inject.} = getConfigDir() / "nimble" / "nimble.ini"
  let configBakFile = getConfigDir() / "nimble" / "nimble.ini.bak"
  if fileExists(configFile):
    safeMoveFile(configFile, configBakFile)

  # Ensure config dir exists
  createDir(getConfigDir() / "nimble")

  body

  # Restore config
  removeFile configFile
  if fileExists(configBakFile):
    safeMoveFile(configBakFile, configFile)

template usePackageListFile*(fileName: string, body: untyped) =
  testRefresh():
    writeFile(configFile, """
      [PackageList]
      name = "local"
      path = "$1"
    """.unindent % (fileName).replace("\\", "\\\\"))
    check execNimble(["refresh"]).exitCode == QuitSuccess
    body

template cleanFile*(fileName: string) =
  removeFile fileName
  defer: removeFile fileName

macro cleanFiles*(fileNames: varargs[string]) =
  result = newStmtList()
  for fn in fileNames:
    result.add quote do: cleanFile(`fn`)

template cleanDir*(dirName: string) =
  removeDir dirName
  defer: removeDir dirName

template createTempDir*(dirName: string) =
  createDir dirName
  defer: removeDir dirName

template cdCleanDir*(dirName: string, body: untyped) =
  cleanDir dirName
  createDir dirName
  cd dirName:
    body

proc filesList(filesNames: seq[string]): string =
  for fileName in filesNames:
    result.addQuoted fileName
    result.add ','

proc developFile*(includes: seq[string], dependencies: seq[string]): string =
  result = """{"version":$#,"includes":[$#],"dependencies":[$#]}""" %
    [$developFileVersion, filesList(includes), filesList(dependencies)]

proc writeDevelopFile*(path: string, includes: seq[string],
                      dependencies: seq[string]) =
  writeFile(path, developFile(includes, dependencies))

# Set env var to propagate nimble binary path
putEnv("NIMBLE_TEST_BINARY_PATH", nimblePath)

# Always recompile.
block:
  # Verbose name is used for exit code so assert is clearer
  let (output, nimbleCompileExitCode) = execCmdEx("nim c --mm:refc " & nimbleCompilePath)
  doAssert nimbleCompileExitCode == QuitSuccess, output
