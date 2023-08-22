#
#           Atlas Package Cloner
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std / [strutils, os, tables, sets, json,
  terminal, hashes, uri]
import versions, parse_requires, compiledpatterns, osutils

export tables, sets, json
export versions, parse_requires, compiledpatterns

const
  MockupRun* = defined(atlasTests)
  UnitTests* = defined(atlasUnitTests)
  TestsDir* = "atlas/tests"

const
  AtlasWorkspace* = "atlas.workspace"

proc getUrl*(x: string): PackageUrl =
  try:
    let u = parseUri(x).PackageUrl
    if u.scheme in ["git", "https", "http", "hg", "file"]:
      result = u
  except UriParseError:
    discard

export uri.`$`, uri.`/`, uri.UriParseError

type
  PackageName* = distinct string
  CfgPath* = distinct string # put into a config `--path:"../x"`

  SemVerField* = enum
    major, minor, patch

  ResolutionAlgorithm* = enum
    MinVer, SemVer, MaxVer

  Dependency* = object
    name*: PackageName
    url*: PackageUrl
    commit*: string
    query*: VersionInterval
    self*: int # position in the graph
    parents*: seq[int] # why we need this dependency
    active*: bool
    hasInstallHooks*: bool
    algo*: ResolutionAlgorithm
    status*: CloneStatus

  DepGraph* = object
    nodes*: seq[Dependency]
    processed*: Table[string, int] # the key is (url / commit)
    byName*: Table[PackageName, seq[int]]
    availableVersions*: Table[PackageName, seq[(string, Version)]] # sorted, latest version comes first
    bestNimVersion*: Version # Nim is a special snowflake

  Flag* = enum
    KeepCommits
    CfgHere
    UsesOverrides
    Keep
    NoColors
    ShowGraph
    AutoEnv
    NoExec
    ListVersions

  MsgKind = enum
    Info = "[Info] ",
    Warning = "[Warning] ",
    Error = "[Error] "

  AtlasContext* = object
    projectDir*, workspace*, depsDir*, currentDir*: string
    hasPackageList*: bool
    flags*: set[Flag]
    p*: Table[string, string] # name -> url mapping
    errors*, warnings*: int
    messages: seq[(MsgKind, PackageName, string)] # delayed output
    overrides*: Patterns
    defaultAlgo*: ResolutionAlgorithm
    when MockupRun:
      step*: int
      mockupSuccess*: bool
    plugins*: PluginInfo

proc `==`*(a, b: CfgPath): bool {.borrow.}

proc `==`*(a, b: PackageName): bool {.borrow.}
proc hash*(a: PackageName): Hash {.borrow.}

const
  InvalidCommit* = "#head" #"<invalid commit>"
  ProduceTest* = false


proc message(c: var AtlasContext; category: string; p: PackageName; arg: string) =
  var msg = category & "(" & p.string & ") " & arg
  stdout.writeLine msg

proc warn*(c: var AtlasContext; p: PackageName; arg: string) =
  c.messages.add (Warning, p, arg)
  inc c.warnings

proc error*(c: var AtlasContext; p: PackageName; arg: string) =
  c.messages.add (Error, p, arg)
  inc c.errors

proc info*(c: var AtlasContext; p: PackageName; arg: string) =
  c.messages.add (Info, p, arg)

proc writeMessage(c: var AtlasContext; k: MsgKind; p: PackageName; arg: string) =
  if NoColors in c.flags:
    message(c, $k, p, arg)
  else:
    let color = case k
                of Info: fgGreen
                of Warning: fgYellow
                of Error: fgRed
    stdout.styledWriteLine(color, styleBright, $k, resetStyle, fgCyan, "(", p.string, ")", resetStyle, " ", arg)

proc writePendingMessages*(c: var AtlasContext) =
  for i in 0..<c.messages.len:
    let (k, p, arg) = c.messages[i]
    writeMessage c, k, p, arg
  c.messages.setLen 0

proc infoNow*(c: var AtlasContext; p: PackageName; arg: string) =
  writeMessage c, Info, p, arg

proc fatal*(msg: string) =
  when defined(debug):
    writeStackTrace()
  quit "[Error] " & msg

proc toName*(p: PackageUrl): PackageName =
  result = PackageName p.path.lastPathComponent
  if result.string.endsWith(".git"):
    result.string.setLen result.string.len - ".git".len

proc toName*(p: string): PackageName =
  if p.contains("://"):
    result = toName getUrl(p)
  else:
    result = PackageName p

template projectFromCurrentDir*(): PackageName =
  PackageName(c.currentDir.lastPathComponent)

template toDestDir*(p: PackageName): string = p.string

proc dependencyDir*(c: AtlasContext; w: Dependency): string =
  result = c.workspace / w.name.string
  if not dirExists(result):
    result = c.depsDir / w.name.string

proc findNimbleFile*(c: AtlasContext; dep: Dependency): string =
  when MockupRun:
    result = TestsDir / dep.name.string & ".nimble"
    doAssert fileExists(result), "file does not exist " & result
  else:
    let dir = dependencyDir(c, dep)
    result = dir / (dep.name.string & ".nimble")
    if not fileExists(result):
      result = ""
      for x in walkFiles(dir / "*.nimble"):
        if result.len == 0:
          result = x
        else:
          # ambiguous .nimble file
          return ""

template withDir*(c: var AtlasContext; dir: string; body: untyped) =
  when MockupRun:
    body
  else:
    let oldDir = getCurrentDir()
    try:
      when ProduceTest:
        echo "Current directory is now ", dir
      setCurrentDir(dir)
      body
    finally:
      setCurrentDir(oldDir)
