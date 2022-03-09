#
#           Atlas Package Cloner
#        (c) Copyright 2021 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Simple tool to automate frequent workflows: Can "clone"
## a Nimble dependency and its dependencies recursively.

import std/[parseopt, strutils, os, osproc, unicode, tables, sets, json, jsonutils]
import parse_requires, osutils, packagesjson

const
  Version = "0.1"
  Usage = "atlas - Nim Package Cloner Version " & Version & """

  (c) 2021 Andreas Rumpf
Usage:
  atlas [options] [command] [arguments]
Command:
  clone url|pkgname     clone a package and all of its dependencies
  search keyw keywB...  search for package that contains the given keywords
  extract file.nimble   extract the requirements and custom commands from
                        the given Nimble file

Options:
  --keepCommits         do not perform any `git checkouts`
  --cfgHere             also create/maintain a nim.cfg in the current
                        working directory
  --version             show the version
  --help                show this help
"""

proc writeHelp() =
  stdout.write(Usage)
  stdout.flushFile()
  quit(0)

proc writeVersion() =
  stdout.write(Version & "\n")
  stdout.flushFile()
  quit(0)

const
  MockupRun = defined(atlasTests)
  TestsDir = "tools/atlas/tests"

type
  PackageName = distinct string
  DepRelation = enum
    normal, strictlyLess, strictlyGreater

  Dependency = object
    name: PackageName
    url, commit: string
    rel: DepRelation # "requires x < 1.0" is silly, but Nimble allows it so we have too.
  AtlasContext = object
    projectDir, workspace: string
    hasPackageList: bool
    keepCommits: bool
    cfgHere: bool
    p: Table[string, string] # name -> url mapping
    processed: HashSet[string] # the key is (url / commit)
    errors: int
    when MockupRun:
      currentDir: string
      step: int
      mockupSuccess: bool

const
  InvalidCommit = "<invalid commit>"
  ProduceTest = false

type
  Command = enum
    GitDiff = "git diff",
    GitTags = "git show-ref --tags",
    GitRevParse = "git rev-parse",
    GitCheckout = "git checkout",
    GitPull = "git pull",
    GitCurrentCommit = "git log -n 1 --format=%H"
    GitMergeBase = "git merge-base"

include testdata

proc exec(c: var AtlasContext; cmd: Command; args: openArray[string]): (string, int) =
  when MockupRun:
    assert TestLog[c.step].cmd == cmd
    case cmd
    of GitDiff, GitTags, GitRevParse, GitPull, GitCurrentCommit:
      result = (TestLog[c.step].output, TestLog[c.step].exitCode)
    of GitCheckout:
      assert args[0] == TestLog[c.step].output
    of GitMergeBase:
      let tmp = TestLog[c.step].output.splitLines()
      assert tmp.len == 4, $tmp.len
      assert tmp[0] == args[0]
      assert tmp[1] == args[1]
      assert tmp[3] == ""
      result[0] = tmp[2]
      result[1] = TestLog[c.step].exitCode
    inc c.step
  else:
    var cmdLine = $cmd
    for i in 0..<args.len:
      cmdLine.add ' '
      cmdLine.add quoteShell(args[i])
    result = osproc.execCmdEx(cmdLine)
    when ProduceTest:
      echo "cmd ", cmd, " args ", args, " --> ", result

proc cloneUrl(c: var AtlasContext; url, dest: string; cloneUsingHttps: bool): string =
  when MockupRun:
    result = ""
  else:
    result = osutils.cloneUrl(url, dest, cloneUsingHttps)
    when ProduceTest:
      echo "cloned ", url, " into ", dest

template withDir*(c: var AtlasContext; dir: string; body: untyped) =
  when MockupRun:
    c.currentDir = dir
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

proc extractRequiresInfo(c: var AtlasContext; nimbleFile: string): NimbleFileInfo =
  result = extractRequiresInfo(nimbleFile)
  when ProduceTest:
    echo "nimble ", nimbleFile, " info ", result

proc toDepRelation(s: string): DepRelation =
  case s
  of "<": strictlyLess
  of ">": strictlyGreater
  else: normal

proc isCleanGit(c: var AtlasContext; dir: string): string =
  result = ""
  let (outp, status) = exec(c, GitDiff, [])
  if outp.len != 0:
    result = "'git diff' not empty"
  elif status != 0:
    result = "'git diff' returned non-zero"

proc message(c: var AtlasContext; category: string; p: PackageName; args: varargs[string]) =
  var msg = category & "(" & p.string & ")"
  for a in args:
    msg.add ' '
    msg.add a
  stdout.writeLine msg
  inc c.errors

proc warn(c: var AtlasContext; p: PackageName; args: varargs[string]) =
  message(c, "[Warning] ", p, args)

proc error(c: var AtlasContext; p: PackageName; args: varargs[string]) =
  message(c, "[Error] ", p, args)

proc sameVersionAs(tag, ver: string): bool =
  const VersionChars = {'0'..'9', '.'}

  proc safeCharAt(s: string; i: int): char {.inline.} =
    if i >= 0 and i < s.len: s[i] else: '\0'

  let idx = find(tag, ver)
  if idx >= 0:
    # we found the version as a substring inside the `tag`. But we
    # need to watch out the the boundaries are not part of a
    # larger/different version number:
    result = safeCharAt(tag, idx-1) notin VersionChars and
      safeCharAt(tag, idx+ver.len) notin VersionChars

proc versionToCommit(c: var AtlasContext; d: Dependency): string =
  let (outp, status) = exec(c, GitTags, [])
  if status == 0:
    var useNextOne = false
    for line in splitLines(outp):
      let commitsAndTags = strutils.splitWhitespace(line)
      if commitsAndTags.len == 2:
        case d.rel
        of normal:
          if commitsAndTags[1].sameVersionAs(d.commit):
            return commitsAndTags[0]
        of strictlyLess:
          if d.commit == InvalidCommit or not commitsAndTags[1].sameVersionAs(d.commit):
            return commitsAndTags[0]
        of strictlyGreater:
          if commitsAndTags[1].sameVersionAs(d.commit):
            useNextOne = true
          elif useNextOne:
            return commitsAndTags[0]

  return ""

proc shortToCommit(c: var AtlasContext; short: string): string =
  let (cc, status) = exec(c, GitRevParse, [short])
  result = if status == 0: strutils.strip(cc) else: ""

proc checkoutGitCommit(c: var AtlasContext; p: PackageName; commit: string) =
  let (_, status) = exec(c, GitCheckout, [commit])
  if status != 0:
    error(c, p, "could not checkout commit", commit)

proc gitPull(c: var AtlasContext; p: PackageName) =
  let (_, status) = exec(c, GitPull, [])
  if status != 0:
    error(c, p, "could not 'git pull'")

proc updatePackages(c: var AtlasContext) =
  if dirExists(c.workspace / PackagesDir):
    withDir(c, c.workspace / PackagesDir):
      gitPull(c, PackageName PackagesDir)
  else:
    withDir c, c.workspace:
      let err = cloneUrl(c, "https://github.com/nim-lang/packages", PackagesDir, false)
      if err != "":
        error c, PackageName(PackagesDir), err

proc fillPackageLookupTable(c: var AtlasContext) =
  if not c.hasPackageList:
    c.hasPackageList = true
    when not MockupRun:
      updatePackages(c)
    let plist = getPackages(when MockupRun: TestsDir else: c.workspace)
    for entry in plist:
      c.p[unicode.toLower entry.name] = entry.url

proc toUrl(c: var AtlasContext; p: string): string =
  if p.isUrl:
    result = p
  else:
    fillPackageLookupTable(c)
    result = c.p.getOrDefault(unicode.toLower p)
  if result.len == 0:
    inc c.errors

proc toName(p: string): PackageName =
  if p.isUrl:
    result = PackageName splitFile(p).name
  else:
    result = PackageName p

proc needsCommitLookup(commit: string): bool {.inline.} =
  '.' in commit or commit == InvalidCommit

proc isShortCommitHash(commit: string): bool {.inline.} =
  commit.len >= 4 and commit.len < 40

proc checkoutCommit(c: var AtlasContext; w: Dependency) =
  let dir = c.workspace / w.name.string
  withDir c, dir:
    if w.commit.len == 0 or cmpIgnoreCase(w.commit, "head") == 0:
      gitPull(c, w.name)
    else:
      let err = isCleanGit(c, dir)
      if err != "":
        warn c, w.name, err
      else:
        let requiredCommit =
          if needsCommitLookup(w.commit): versionToCommit(c, w)
          elif isShortCommitHash(w.commit): shortToCommit(c, w.commit)
          else: w.commit
        let (cc, status) = exec(c, GitCurrentCommit, [])
        let currentCommit = strutils.strip(cc)
        if requiredCommit == "" or status != 0:
          if requiredCommit == "" and w.commit == InvalidCommit:
            warn c, w.name, "package has no tagged releases"
          else:
            warn c, w.name, "cannot find specified version/commit", w.commit
        else:
          if currentCommit != requiredCommit:
            # checkout the later commit:
            # git merge-base --is-ancestor <commit> <commit>
            let (cc, status) = exec(c, GitMergeBase, [currentCommit, requiredCommit])
            let mergeBase = strutils.strip(cc)
            if status == 0 and (mergeBase == currentCommit or mergeBase == requiredCommit):
              # conflict resolution: pick the later commit:
              if mergeBase == currentCommit:
                checkoutGitCommit(c, w.name, requiredCommit)
            else:
              checkoutGitCommit(c, w.name, requiredCommit)
              when false:
                warn c, w.name, "do not know which commit is more recent:",
                  currentCommit, "(current) or", w.commit, " =", requiredCommit, "(required)"

proc findNimbleFile(c: AtlasContext; dep: Dependency): string =
  when MockupRun:
    result = TestsDir / dep.name.string & ".nimble"
    doAssert fileExists(result), "file does not exist " & result
  else:
    result = c.workspace / dep.name.string / (dep.name.string & ".nimble")
    if not fileExists(result):
      result = ""
      for x in walkFiles(c.workspace / dep.name.string / "*.nimble"):
        if result.len == 0:
          result = x
        else:
          # ambiguous .nimble file
          return ""

proc addUniqueDep(c: var AtlasContext; work: var seq[Dependency];
                  tokens: seq[string]) =
  let oldErrors = c.errors
  let url = toUrl(c, tokens[0])
  if oldErrors != c.errors:
    warn c, toName(tokens[0]), "cannot resolve package name"
  elif not c.processed.containsOrIncl(url / tokens[2]):
    work.add Dependency(name: toName(tokens[0]), url: url, commit: tokens[2],
                        rel: toDepRelation(tokens[1]))

proc collectNewDeps(c: var AtlasContext; work: var seq[Dependency];
                    dep: Dependency; result: var seq[string];
                    isMainProject: bool) =
  let nimbleFile = findNimbleFile(c, dep)
  if nimbleFile != "":
    let nimbleInfo = extractRequiresInfo(c, nimbleFile)
    for r in nimbleInfo.requires:
      var tokens: seq[string] = @[]
      for token in tokenizeRequires(r):
        tokens.add token
      if tokens.len == 1:
        # nimx uses dependencies like 'requires "sdl2"'.
        # Via this hack we map them to the first tagged release.
        # (See the `isStrictlySmallerThan` logic.)
        tokens.add "<"
        tokens.add InvalidCommit
      elif tokens.len == 2 and tokens[1].startsWith("#"):
        # Dependencies can also look like 'requires "sdl2#head"
        var commit = tokens[1][1 .. ^1]
        tokens[1] = "=="
        tokens.add commit

      if tokens.len >= 3 and cmpIgnoreCase(tokens[0], "nim") != 0:
        c.addUniqueDep work, tokens

    result.add dep.name.string / nimbleInfo.srcDir
  else:
    result.add dep.name.string

proc clone(c: var AtlasContext; start: string): seq[string] =
  # non-recursive clone.
  let oldErrors = c.errors
  var work = @[Dependency(name: toName(start), url: toUrl(c, start), commit: "")]

  if oldErrors != c.errors:
    error c, toName(start), "cannot resolve package name"
    return

  c.projectDir = c.workspace / work[0].name.string
  result = @[]
  var i = 0
  while i < work.len:
    let w = work[i]
    let oldErrors = c.errors
    if not dirExists(c.workspace / w.name.string):
      withDir c, c.workspace:
        let err = cloneUrl(c, w.url, w.name.string, false)
        if err != "":
          error c, w.name, err
    if oldErrors == c.errors:
      if not c.keepCommits: checkoutCommit(c, w)
      # even if the checkout fails, we can make use of the somewhat
      # outdated .nimble file to clone more of the most likely still relevant
      # dependencies:
      collectNewDeps(c, work, w, result, i == 0)
    inc i

const
  configPatternBegin = "############# begin Atlas config section ##########\n"
  configPatternEnd =   "############# end Atlas config section   ##########\n"

proc patchNimCfg(c: var AtlasContext; deps: seq[string]; cfgHere: bool) =
  var paths = "--noNimblePath\n"
  if cfgHere:
    let cwd = getCurrentDir()
    for d in deps:
      let x = relativePath(c.workspace / d, cwd, '/')
      paths.add "--path:\"" & x & "\"\n"
  else:
    for d in deps:
      paths.add "--path:\"../" & d.replace("\\", "/") & "\"\n"

  var cfgContent = configPatternBegin & paths & configPatternEnd

  when MockupRun:
    assert readFile(TestsDir / "nim.cfg") == cfgContent
    c.mockupSuccess = true
  else:
    let cfg = if cfgHere: getCurrentDir() / "nim.cfg"
              else: c.projectDir / "nim.cfg"
    if not fileExists(cfg):
      writeFile(cfg, cfgContent)
    else:
      let content = readFile(cfg)
      let start = content.find(configPatternBegin)
      if start >= 0:
        cfgContent = content.substr(0, start-1) & cfgContent
        let theEnd = content.find(configPatternEnd, start)
        if theEnd >= 0:
          cfgContent.add content.substr(theEnd+len(configPatternEnd))
      else:
        cfgContent = content & "\n" & cfgContent
      if cfgContent != content:
        # do not touch the file if nothing changed
        # (preserves the file date information):
        writeFile(cfg, cfgContent)

proc error*(msg: string) =
  when defined(debug):
    writeStackTrace()
  quit "[Error] " & msg

proc main =
  var action = ""
  var args: seq[string] = @[]
  template singleArg() =
    if args.len != 1:
      error action & " command takes a single package name"

  template noArgs() =
    if args.len != 0:
      error action & " command takes no arguments"

  var c = AtlasContext(
    projectDir: getCurrentDir(),
    workspace: getCurrentDir())

  for kind, key, val in getopt():
    case kind
    of cmdArgument:
      if action.len == 0:
        action = key.normalize
      else:
        args.add key
    of cmdLongOption, cmdShortOption:
      case normalize(key)
      of "help", "h": writeHelp()
      of "version", "v": writeVersion()
      of "keepcommits": c.keepCommits = true
      of "cfghere": c.cfgHere = true
      else: writeHelp()
    of cmdEnd: assert false, "cannot happen"

  while c.workspace.len > 0 and dirExists(c.workspace / ".git"):
    c.workspace = c.workspace.parentDir()

  case action
  of "":
    error "No action."
  of "clone":
    singleArg()
    let deps = clone(c, args[0])
    patchNimCfg c, deps, false
    if c.cfgHere:
      patchNimCfg c, deps, true
    when MockupRun:
      if not c.mockupSuccess:
        error "There were problems."
    else:
      if c.errors > 0:
        error "There were problems."
  of "refresh":
    noArgs()
    updatePackages(c)
  of "search", "list":
    updatePackages(c)
    search getPackages(c.workspace), args
  of "extract":
    singleArg()
    if fileExists(args[0]):
      echo toJson(extractRequiresInfo(args[0]))
    else:
      error "File does not exist: " & args[0]
  else:
    error "Invalid action: " & action

when isMainModule:
  main()

when false:
  # some testing code for the `patchNimCfg` logic:
  var c = AtlasContext(
    projectDir: getCurrentDir(),
    workspace: getCurrentDir().parentDir)

  patchNimCfg(c, @[PackageName"abc", PackageName"xyz"])

when false:
  assert sameVersionAs("v0.2.0", "0.2.0")
  assert sameVersionAs("v1", "1")

  assert sameVersionAs("1.90", "1.90")

  assert sameVersionAs("v1.2.3-zuzu", "1.2.3")
  assert sameVersionAs("foo-1.2.3.4", "1.2.3.4")

  assert not sameVersionAs("foo-1.2.3.4", "1.2.3")
  assert not sameVersionAs("foo", "1.2.3")
  assert not sameVersionAs("", "1.2.3")
