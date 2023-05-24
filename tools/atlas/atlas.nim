#
#           Atlas Package Cloner
#        (c) Copyright 2021 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Simple tool to automate frequent workflows: Can "clone"
## a Nimble dependency and its dependencies recursively.

import std / [parseopt, strutils, os, osproc, tables, sets, json, jsonutils]
import parse_requires, osutils, packagesjson

from unicode import nil

const
  Version = "0.3"
  LockFileName = "atlas.lock"
  Usage = "atlas - Nim Package Cloner Version " & Version & """

  (c) 2021 Andreas Rumpf
Usage:
  atlas [options] [command] [arguments]
Command:
  clone url|pkgname     clone a package and all of its dependencies
  update url|pkgname    update a package and all of its dependencies
  install proj.nimble   use the .nimble file to setup the project's dependencies
  search keyw keywB...  search for package that contains the given keywords
  extract file.nimble   extract the requirements and custom commands from
                        the given Nimble file
  updateWorkspace [filter]
                        update every package in the workspace that has a remote
                        URL that matches `filter` if a filter is given
  build|test|doc|tasks  currently delegates to `nimble build|test|doc`
  task <taskname>       currently delegates to `nimble <taskname>`

Options:
  --keepCommits         do not perform any `git checkouts`
  --cfgHere             also create/maintain a nim.cfg in the current
                        working directory
  --workspace=DIR       use DIR as workspace
  --deps=DIR            store dependencies in DIR instead of the workspace
                        (if DIR is a relative path, it is interpreted to
                        be relative to the workspace)
  --genlock             generate a lock file (use with `clone` and `update`)
  --uselock             use the lock file for the build
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
  LockOption = enum
    noLock, genLock, useLock

  LockFileEntry = object
    dir, url, commit: string

  PackageName = distinct string
  DepRelation = enum
    normal, strictlyLess, strictlyGreater

  Dependency = object
    name: PackageName
    url, commit: string
    rel: DepRelation # "requires x < 1.0" is silly, but Nimble allows it so we have too.
  AtlasContext = object
    projectDir, workspace, depsDir: string
    hasPackageList: bool
    keepCommits: bool
    cfgHere: bool
    p: Table[string, string] # name -> url mapping
    processed: HashSet[string] # the key is (url / commit)
    errors: int
    lockOption: LockOption
    lockFileToWrite: seq[LockFileEntry]
    lockFileToUse: Table[string, LockFileEntry]
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

proc silentExec(cmd: string; args: openArray[string]): (string, int) =
  var cmdLine = cmd
  for i in 0..<args.len:
    cmdLine.add ' '
    cmdLine.add quoteShell(args[i])
  result = osproc.execCmdEx(cmdLine)

proc nimbleExec(cmd: string; args: openArray[string]) =
  var cmdLine = "nimble " & cmd
  for i in 0..<args.len:
    cmdLine.add ' '
    cmdLine.add quoteShell(args[i])
  discard os.execShellCmd(cmdLine)

proc exec(c: var AtlasContext; cmd: Command; args: openArray[string]): (string, int) =
  when MockupRun:
    assert TestLog[c.step].cmd == cmd, $(TestLog[c.step].cmd, cmd)
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
    result = silentExec($cmd, args)
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

proc isCleanGit(c: var AtlasContext): string =
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
    result = getUrlFromGithub(p)
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

proc getRequiredCommit(c: var AtlasContext; w: Dependency): string =
  if needsCommitLookup(w.commit): versionToCommit(c, w)
  elif isShortCommitHash(w.commit): shortToCommit(c, w.commit)
  else: w.commit

proc getRemoteUrl(): string =
  execProcess("git config --get remote.origin.url").strip()

proc genLockEntry(c: var AtlasContext; w: Dependency; dir: string) =
  let url = getRemoteUrl()
  var commit = getRequiredCommit(c, w)
  if commit.len == 0 or needsCommitLookup(commit):
    commit = execProcess("git log -1 --pretty=format:%H").strip()
  c.lockFileToWrite.add LockFileEntry(dir: relativePath(dir, c.workspace, '/'), url: url, commit: commit)

proc commitFromLockFile(c: var AtlasContext; dir: string): string =
  let url = getRemoteUrl()
  let d = relativePath(dir, c.workspace, '/')
  if d in c.lockFileToUse:
    result = c.lockFileToUse[d].commit
    let wanted = c.lockFileToUse[d].url
    if wanted != url:
      error c, PackageName(d), "remote URL has been compromised: got: " &
          url & " but wanted: " & wanted
  else:
    error c, PackageName(d), "package is not listed in the lock file"

proc checkoutCommit(c: var AtlasContext; w: Dependency) =
  var dir = c.workspace / w.name.string
  if not dirExists(dir):
    dir = c.depsDir / w.name.string

  withDir c, dir:
    if c.lockOption == genLock:
      genLockEntry(c, w, dir)
    elif c.lockOption == useLock:
      checkoutGitCommit(c, w.name, commitFromLockFile(c, dir))
    elif w.commit.len == 0 or cmpIgnoreCase(w.commit, "head") == 0:
      gitPull(c, w.name)
    else:
      let err = isCleanGit(c)
      if err != "":
        warn c, w.name, err
      else:
        let requiredCommit = getRequiredCommit(c, w)
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

template toDestDir(p: PackageName): string = p.string

proc collectDeps(c: var AtlasContext; work: var seq[Dependency];
                 dep: Dependency; nimbleFile: string): string =
  # If there is a .nimble file, return the dependency path & srcDir
  # else return "".
  assert nimbleFile != ""
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
  result = toDestDir(dep.name) / nimbleInfo.srcDir

proc collectNewDeps(c: var AtlasContext; work: var seq[Dependency];
                    dep: Dependency; result: var seq[string];
                    isMainProject: bool) =
  let nimbleFile = findNimbleFile(c, dep)
  if nimbleFile != "":
    let x = collectDeps(c, work, dep, nimbleFile)
    result.add x
  else:
    result.add toDestDir(dep.name)

proc cloneLoop(c: var AtlasContext; work: var seq[Dependency]): seq[string] =
  result = @[]
  var i = 0
  while i < work.len:
    let w = work[i]
    let destDir = toDestDir(w.name)
    let oldErrors = c.errors

    if not dirExists(c.workspace / destDir) and not dirExists(c.depsDir / destDir):
      withDir c, (if i == 0: c.workspace else: c.depsDir):
        let err = cloneUrl(c, w.url, destDir, false)
        if err != "":
          error c, w.name, err
    if oldErrors == c.errors:
      if not c.keepCommits: checkoutCommit(c, w)
      # even if the checkout fails, we can make use of the somewhat
      # outdated .nimble file to clone more of the most likely still relevant
      # dependencies:
      collectNewDeps(c, work, w, result, i == 0)
    inc i

proc readLockFile(c: var AtlasContext) =
  let jsonAsStr = readFile(c.projectDir / LockFileName)
  let jsonTree = parseJson(jsonAsStr)
  let data = to(jsonTree, seq[LockFileEntry])
  c.lockFileToUse = initTable[string, LockFileEntry]()
  for d in items(data):
    c.lockFileToUse[d.dir] = d

proc clone(c: var AtlasContext; start: string): seq[string] =
  # non-recursive clone.
  let url = toUrl(c, start)
  var work = @[Dependency(name: toName(start), url: url, commit: "")]

  if url == "":
    error c, toName(start), "cannot resolve package name"
    return

  c.projectDir = c.workspace / toDestDir(work[0].name)
  if c.lockOption == useLock:
    readLockFile c
  result = cloneLoop(c, work)
  if c.lockOption == genLock:
    writeFile c.projectDir / LockFileName, toJson(c.lockFileToWrite).pretty

const
  configPatternBegin = "############# begin Atlas config section ##########\n"
  configPatternEnd =   "############# end Atlas config section   ##########\n"

proc patchNimCfg(c: var AtlasContext; deps: seq[string]; cfgPath: string) =
  var paths = "--noNimblePath\n"
  for d in deps:
    let pkgname = toDestDir d.PackageName
    let pkgdir = if dirExists(c.workspace / pkgname): c.workspace / pkgname
                 else: c.depsDir / pkgName
    let x = relativePath(pkgdir, cfgPath, '/')
    paths.add "--path:\"" & x & "\"\n"
  var cfgContent = configPatternBegin & paths & configPatternEnd

  when MockupRun:
    assert readFile(TestsDir / "nim.cfg") == cfgContent
    c.mockupSuccess = true
  else:
    let cfg = cfgPath / "nim.cfg"
    if cfgPath.len > 0 and not dirExists(cfgPath):
      error(c, c.projectDir.PackageName, "could not write the nim.cfg")
    elif not fileExists(cfg):
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

proc findSrcDir(c: var AtlasContext): string =
  for nimbleFile in walkPattern("*.nimble"):
    let nimbleInfo = extractRequiresInfo(c, nimbleFile)
    return nimbleInfo.srcDir
  return ""

proc installDependencies(c: var AtlasContext; nimbleFile: string) =
  # 1. find .nimble file in CWD
  # 2. install deps from .nimble
  var work: seq[Dependency] = @[]
  let (_, pkgname, _) = splitFile(nimbleFile)
  let dep = Dependency(name: toName(pkgname), url: "", commit: "")
  discard collectDeps(c, work, dep, nimbleFile)
  let paths = cloneLoop(c, work)
  patchNimCfg(c, paths, if c.cfgHere: getCurrentDir() else: findSrcDir(c))

proc updateWorkspace(c: var AtlasContext; dir, filter: string) =
  for kind, file in walkDir(dir):
    if kind == pcDir and dirExists(file / ".git"):
      c.withDir file:
        let pkg = PackageName(file)
        let (remote, _) = osproc.execCmdEx("git remote -v")
        if filter.len == 0 or filter in remote:
          let diff = isCleanGit(c)
          if diff != "":
            warn(c, pkg, "has uncommitted changes; skipped")
          else:
            let (branch, _) = osproc.execCmdEx("git rev-parse --abbrev-ref HEAD")
            if branch.strip.len > 0:
              let (output, exitCode) = osproc.execCmdEx("git pull origin " & branch.strip)
              if exitCode != 0:
                error c, pkg, output
              else:
                message(c, "[Hint] ", pkg, "successfully updated")
            else:
              error c, pkg, "could not fetch current branch name"

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
    workspace: "")

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
      of "workspace":
        if val.len > 0:
          c.workspace = val
          createDir(val)
        else:
          writeHelp()
      of "deps":
        if val.len > 0:
          c.depsDir = val
        else:
          writeHelp()
      of "cfghere": c.cfgHere = true
      of "genlock":
        if c.lockOption != useLock:
          c.lockOption = genLock
        else:
          writeHelp()
      of "uselock":
        if c.lockOption != genLock:
          c.lockOption = useLock
        else:
          writeHelp()
      else: writeHelp()
    of cmdEnd: assert false, "cannot happen"

  if c.workspace.len > 0:
    if not dirExists(c.workspace): error "Workspace directory '" & c.workspace & "' not found."
  else:
    c.workspace = getCurrentDir()
    while c.workspace.len > 0 and dirExists(c.workspace / ".git"):
      c.workspace = c.workspace.parentDir()

  when MockupRun:
    c.depsDir = c.workspace
  else:
    if c.depsDir.len > 0:
      if c.depsDir == ".":
        c.depsDir = c.workspace
      elif not isAbsolute(c.depsDir):
        c.depsDir = c.workspace / c.depsDir
    else:
      c.depsDir = c.workspace / "_deps"
    createDir(c.depsDir)

  echo "Using workspace ", c.workspace

  case action
  of "":
    error "No action."
  of "clone", "update":
    singleArg()
    let deps = clone(c, args[0])
    patchNimCfg c, deps, if c.cfgHere: getCurrentDir() else: findSrcDir(c)
    when MockupRun:
      if not c.mockupSuccess:
        error "There were problems."
    else:
      if c.errors > 0:
        error "There were problems."
  of "install":
    if args.len > 1:
      error "install command takes a single argument"
    var nimbleFile = ""
    if args.len == 1:
      nimbleFile = args[0]
    else:
      for x in walkPattern("*.nimble"):
        nimbleFile = x
        break
    if nimbleFile.len == 0:
      error "could not find a .nimble file"
    installDependencies(c, nimbleFile)
  of "refresh":
    noArgs()
    updatePackages(c)
  of "search", "list":
    updatePackages(c)
    search getPackages(c.workspace), args
  of "updateworkspace":
    updateWorkspace(c, c.workspace, if args.len == 0: "" else: args[0])
    updateWorkspace(c, c.depsDir, if args.len == 0: "" else: args[0])
  of "extract":
    singleArg()
    if fileExists(args[0]):
      echo toJson(extractRequiresInfo(args[0]))
    else:
      error "File does not exist: " & args[0]
  of "build", "test", "doc", "tasks":
    nimbleExec(action, args)
  of "task":
    nimbleExec("", args)
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
