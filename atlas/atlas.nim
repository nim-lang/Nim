#
#           Atlas Package Cloner
#        (c) Copyright 2021 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Simple tool to automate frequent workflows: Can "clone"
## a Nimble dependency and its dependencies recursively.

import std / [parseopt, strutils, os, osproc, tables, sets, json, jsonutils,
  parsecfg, streams, terminal, strscans, hashes]
import parse_requires, osutils, packagesjson, compiledpatterns

from unicode import nil

const
  AtlasVersion = "0.4"
  LockFileName = "atlas.lock"
  AtlasWorkspace = "atlas.workspace"
  Usage = "atlas - Nim Package Cloner Version " & AtlasVersion & """

  (c) 2021 Andreas Rumpf
Usage:
  atlas [options] [command] [arguments]
Command:
  init                  initializes the current directory as a workspace
    --deps=DIR          use DIR as the directory for dependencies
                        (default: store directly in the workspace)

  use url|pkgname       clone a package and all of its dependencies and make
                        it importable for the current project
  clone url|pkgname     clone a package and all of its dependencies
  update url|pkgname    update a package and all of its dependencies
  install proj.nimble   use the .nimble file to setup the project's dependencies
  search keyw keywB...  search for package that contains the given keywords
  extract file.nimble   extract the requirements and custom commands from
                        the given Nimble file
  updateProjects [filter]
                        update every project that has a remote
                        URL that matches `filter` if a filter is given
  updateDeps [filter]
                        update every dependency that has a remote
                        URL that matches `filter` if a filter is given
  tag [major|minor|patch]
                        add and push a new tag, input must be one of:
                        ['major'|'minor'|'patch'] or a SemVer tag like ['1.0.3']
                        or a letter ['a'..'z']: a.b.c.d.e.f.g
  outdated              list the packages that are outdated
  build|test|doc|tasks  currently delegates to `nimble build|test|doc`
  task <taskname>       currently delegates to `nimble <taskname>`
  env <nimversion>      setup a Nim virtual environment
    --keep              keep the c_code subdirectory

Options:
  --keepCommits         do not perform any `git checkouts`
  --cfgHere             also create/maintain a nim.cfg in the current
                        working directory
  --workspace=DIR       use DIR as workspace
  --project=DIR         use DIR as the current project
  --genlock             generate a lock file (use with `clone` and `update`)
  --uselock             use the lock file for the build
  --autoenv             detect the minimal Nim $version and setup a
                        corresponding Nim virtual environment
  --autoinit            auto initialize a workspace
  --colors=on|off       turn on|off colored output
  --showGraph           show the dependency graph
  --version             show the version
  --help                show this help
"""

proc writeHelp() =
  stdout.write(Usage)
  stdout.flushFile()
  quit(0)

proc writeVersion() =
  stdout.write(AtlasVersion & "\n")
  stdout.flushFile()
  quit(0)

const
  MockupRun = defined(atlasTests)
  TestsDir = "atlas/tests"

type
  LockMode = enum
    noLock, genLock, useLock

  LockFileEntry = object
    url, commit: string

  PackageName = distinct string
  CfgPath = distinct string # put into a config `--path:"../x"`
  DepRelation = enum
    normal, strictlyLess, strictlyGreater

  SemVerField = enum
    major, minor, patch

  Dependency = object
    name: PackageName
    url, commit: string
    rel: DepRelation # "requires x < 1.0" is silly, but Nimble allows it so we have too.
    self: int # position in the graph
    parents: seq[int] # why we need this dependency
    active: bool
  DepGraph = object
    nodes: seq[Dependency]
    processed: Table[string, int] # the key is (url / commit)
    byName: Table[PackageName, seq[int]]
    bestNimVersion: (int, int, int) # Nim is a special snowflake

  LockFile = object # serialized as JSON so an object for extensibility
    items: OrderedTable[string, LockFileEntry]

  Flag = enum
    KeepCommits
    CfgHere
    UsesOverrides
    Keep
    NoColors
    ShowGraph
    AutoEnv

  AtlasContext = object
    projectDir, workspace, depsDir, currentDir: string
    hasPackageList: bool
    flags: set[Flag]
    p: Table[string, string] # name -> url mapping
    errors, warnings: int
    overrides: Patterns
    lockMode: LockMode
    lockFile: LockFile
    when MockupRun:
      step: int
      mockupSuccess: bool

proc `==`*(a, b: CfgPath): bool {.borrow.}

proc `==`*(a, b: PackageName): bool {.borrow.}
proc hash*(a: PackageName): Hash {.borrow.}

const
  InvalidCommit = "<invalid commit>"
  ProduceTest = false

type
  Command = enum
    GitDiff = "git diff",
    GitTag = "git tag",
    GitTags = "git show-ref --tags",
    GitLastTaggedRef = "git rev-list --tags --max-count=1",
    GitDescribe = "git describe",
    GitRevParse = "git rev-parse",
    GitCheckout = "git checkout",
    GitPush = "git push origin",
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
    of GitDiff, GitTag, GitTags, GitLastTaggedRef, GitDescribe, GitRevParse, GitPush, GitPull, GitCurrentCommit:
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

proc message(c: var AtlasContext; category: string; p: PackageName; arg: string) =
  var msg = category & "(" & p.string & ") " & arg
  stdout.writeLine msg

proc warn(c: var AtlasContext; p: PackageName; arg: string) =
  if NoColors in c.flags:
    message(c, "[Warning] ", p, arg)
  else:
    stdout.styledWriteLine(fgYellow, styleBright, "[Warning] ", resetStyle, fgCyan, "(", p.string, ")", resetStyle, " ", arg)
  inc c.warnings

proc error(c: var AtlasContext; p: PackageName; arg: string) =
  if NoColors in c.flags:
    message(c, "[Error] ", p, arg)
  else:
    stdout.styledWriteLine(fgRed, styleBright, "[Error] ", resetStyle, fgCyan, "(", p.string, ")", resetStyle, " ", arg)
  inc c.errors

proc info(c: var AtlasContext; p: PackageName; arg: string) =
  if NoColors in c.flags:
    message(c, "[Info] ", p, arg)
  else:
    stdout.styledWriteLine(fgGreen, styleBright, "[Info] ", resetStyle, fgCyan, "(", p.string, ")", resetStyle, " ", arg)

template projectFromCurrentDir(): PackageName = PackageName(c.currentDir.splitPath.tail)

proc readableFile(s: string): string = relativePath(s, getCurrentDir())

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

proc gitDescribeRefTag(c: var AtlasContext; commit: string): string =
  let (lt, status) = exec(c, GitDescribe, ["--tags", commit])
  result = if status == 0: strutils.strip(lt) else: ""

proc getLastTaggedCommit(c: var AtlasContext): string =
  let (ltr, status) = exec(c, GitLastTaggedRef, [])
  if status == 0:
    let lastTaggedRef = ltr.strip()
    let lastTag = gitDescribeRefTag(c, lastTaggedRef)
    if lastTag.len != 0:
      result = lastTag

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
          if d.commit == InvalidCommit:
            return getLastTaggedCommit(c)
          elif not commitsAndTags[1].sameVersionAs(d.commit):
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
    error(c, p, "could not checkout commit " & commit)

proc gitPull(c: var AtlasContext; p: PackageName) =
  let (_, status) = exec(c, GitPull, [])
  if status != 0:
    error(c, p, "could not 'git pull'")

proc gitTag(c: var AtlasContext; tag: string) =
  let (_, status) = exec(c, GitTag, [tag])
  if status != 0:
    error(c, c.projectDir.PackageName, "could not 'git tag " & tag & "'")

proc pushTag(c: var AtlasContext; tag: string) =
  let (outp, status) = exec(c, GitPush, [tag])
  if status != 0:
    error(c, c.projectDir.PackageName, "could not 'git push " & tag & "'")
  elif outp.strip() == "Everything up-to-date":
    info(c, c.projectDir.PackageName, "is up-to-date")
  else:
    info(c, c.projectDir.PackageName, "successfully pushed tag: " & tag)

proc incrementTag(c: var AtlasContext; lastTag: string; field: Natural): string =
  var startPos =
    if lastTag[0] in {'0'..'9'}: 0
    else: 1
  var endPos = lastTag.find('.', startPos)
  if field >= 1:
    for i in 1 .. field:
      if endPos == -1:
        error c, projectFromCurrentDir(), "the last tag '" & lastTag & "' is missing . periods"
        return ""
      startPos = endPos + 1
      endPos = lastTag.find('.', startPos)
  if endPos == -1:
    endPos = len(lastTag)
  let patchNumber = parseInt(lastTag[startPos..<endPos])
  lastTag[0..<startPos] & $(patchNumber + 1) & lastTag[endPos..^1]

proc incrementLastTag(c: var AtlasContext; field: Natural): string =
  let (ltr, status) = exec(c, GitLastTaggedRef, [])
  if status == 0:
    let
      lastTaggedRef = ltr.strip()
      lastTag = gitDescribeRefTag(c, lastTaggedRef)
      currentCommit = exec(c, GitCurrentCommit, [])[0].strip()

    if lastTaggedRef == currentCommit:
      info c, c.projectDir.PackageName, "the current commit '" & currentCommit & "' is already tagged '" & lastTag & "'"
      lastTag
    else:
      incrementTag(c, lastTag, field)
  else: "v0.0.1" # assuming no tags have been made yet

proc tag(c: var AtlasContext; tag: string) =
  gitTag(c, tag)
  pushTag(c, tag)

proc tag(c: var AtlasContext; field: Natural) =
  let oldErrors = c.errors
  let newTag = incrementLastTag(c, field)
  if c.errors == oldErrors:
    tag(c, newTag)

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

proc toName(p: string): PackageName =
  if p.isUrl:
    result = PackageName splitFile(p).name
  else:
    result = PackageName p

proc generateDepGraph(c: var AtlasContext; g: DepGraph) =
  proc repr(w: Dependency): string =
    if w.url.endsWith("/"): w.url & w.commit
    else: w.url & "/" & w.commit

  var dotGraph = ""
  for i in 0 ..< g.nodes.len:
    dotGraph.addf("\"$1\" [label=\"$2\"];\n", [g.nodes[i].repr, if g.nodes[i].active: "" else: "unused"])
  for i in 0 ..< g.nodes.len:
    for p in items g.nodes[i].parents:
      if p >= 0:
        dotGraph.addf("\"$1\" -> \"$2\";\n", [g.nodes[p].repr, g.nodes[i].repr])
  let dotFile = c.currentDir / "deps.dot"
  writeFile(dotFile, "digraph deps {\n$1}\n" % dotGraph)
  let graphvizDotPath = findExe("dot")
  if graphvizDotPath.len == 0:
    #echo("gendepend: Graphviz's tool dot is required, " &
    #  "see https://graphviz.org/download for downloading")
    discard
  else:
    discard execShellCmd("dot -Tpng -odeps.png " & quoteShell(dotFile))

proc setupNimEnv(c: var AtlasContext; nimVersion: string)

proc afterGraphActions(c: var AtlasContext; g: DepGraph) =
  if ShowGraph in c.flags:
    generateDepGraph c, g
  if AutoEnv in c.flags and g.bestNimVersion != (0, 0, 0):
    let v = $g.bestNimVersion[0] & "." & $g.bestNimVersion[1] & "." & $g.bestNimVersion[2]
    setupNimEnv c, v

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

proc genLockEntry(c: var AtlasContext; w: Dependency) =
  let url = getRemoteUrl()
  var commit = getRequiredCommit(c, w)
  if commit.len == 0 or needsCommitLookup(commit):
    commit = execProcess("git log -1 --pretty=format:%H").strip()
  c.lockFile.items[w.name.string] = LockFileEntry(url: url, commit: commit)

proc commitFromLockFile(c: var AtlasContext; w: Dependency): string =
  let url = getRemoteUrl()
  let entry = c.lockFile.items.getOrDefault(w.name.string)
  if entry.commit.len > 0:
    result = entry.commit
    if entry.url != url:
      error c, w.name, "remote URL has been compromised: got: " &
          url & " but wanted: " & entry.url
  else:
    error c, w.name, "package is not listed in the lock file"

proc dependencyDir(c: AtlasContext; w: Dependency): string =
  result = c.workspace / w.name.string
  if not dirExists(result):
    result = c.depsDir / w.name.string

const
  FileProtocol = "file://"
  ThisVersion = "current_version.atlas"

proc selectNode(c: var AtlasContext; g: var DepGraph; w: Dependency) =
  # all other nodes of the same project name are not active
  for e in items g.byName[w.name]:
    g.nodes[e].active = e == w.self
  if c.lockMode == genLock:
    if w.url.startsWith(FileProtocol):
      c.lockFile.items[w.name.string] = LockFileEntry(url: w.url, commit: w.commit)
    else:
      genLockEntry(c, w)

proc checkoutCommit(c: var AtlasContext; g: var DepGraph; w: Dependency) =
  let dir = dependencyDir(c, w)
  withDir c, dir:
    if c.lockMode == useLock:
      checkoutGitCommit(c, w.name, commitFromLockFile(c, w))
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
            warn c, w.name, "cannot find specified version/commit " & w.commit
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
                selectNode c, g, w
            else:
              checkoutGitCommit(c, w.name, requiredCommit)
              selectNode c, g, w
              when false:
                warn c, w.name, "do not know which commit is more recent:",
                  currentCommit, "(current) or", w.commit, " =", requiredCommit, "(required)"

proc findNimbleFile(c: AtlasContext; dep: Dependency): string =
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

proc addUnique[T](s: var seq[T]; elem: sink T) =
  if not s.contains(elem): s.add elem

proc addUniqueDep(c: var AtlasContext; g: var DepGraph; parent: int;
                  tokens: seq[string]) =
  let pkgName = tokens[0]
  let oldErrors = c.errors
  let url = toUrl(c, pkgName)
  if oldErrors != c.errors:
    warn c, toName(pkgName), "cannot resolve package name"
  else:
    let key = url / tokens[2]
    if g.processed.hasKey(key):
      g.nodes[g.processed[key]].parents.addUnique parent
    else:
      let self = g.nodes.len
      g.byName.mgetOrPut(toName(pkgName), @[]).add self
      g.processed[key] = self
      if c.lockMode == useLock:
        if c.lockfile.items.contains(pkgName):
          g.nodes.add Dependency(name: toName(pkgName),
                              url: c.lockfile.items[pkgName].url,
                              commit: c.lockfile.items[pkgName].commit,
                              rel: normal,
                              self: self,
                              parents: @[parent])
        else:
          error c, toName(pkgName), "package is not listed in the lock file"
      else:
        g.nodes.add Dependency(name: toName(pkgName), url: url, commit: tokens[2],
                               rel: toDepRelation(tokens[1]),
                               self: self,
                               parents: @[parent])

template toDestDir(p: PackageName): string = p.string

proc readLockFile(filename: string): LockFile =
  let jsonAsStr = readFile(filename)
  let jsonTree = parseJson(jsonAsStr)
  result = to(jsonTree, LockFile)

proc rememberNimVersion(g: var DepGraph; tokens: seq[string]) =
  if tokens[1] in ["==", ">="]:
    var v = (0, 0, 0)
    if scanf(tokens[2], "$i.$i.$i", v[0], v[1], v[2]):
      if v > g.bestNimVersion: g.bestNimVersion = v

proc collectDeps(c: var AtlasContext; g: var DepGraph; parent: int;
                 dep: Dependency; nimbleFile: string): CfgPath =
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

    if tokens.len >= 3:
      if cmpIgnoreCase(tokens[0], "nim") != 0:
        c.addUniqueDep g, parent, tokens
      else:
        rememberNimVersion g, tokens
  result = CfgPath(toDestDir(dep.name) / nimbleInfo.srcDir)

proc collectNewDeps(c: var AtlasContext; g: var DepGraph; parent: int;
                    dep: Dependency): CfgPath =
  let nimbleFile = findNimbleFile(c, dep)
  if nimbleFile != "":
    result = collectDeps(c, g, parent, dep, nimbleFile)
  else:
    result = CfgPath toDestDir(dep.name)

proc selectDir(a, b: string): string = (if dirExists(a): a else: b)

proc copyFromDisk(c: var AtlasContext; w: Dependency) =
  let destDir = toDestDir(w.name)
  var u = w.url.substr(FileProtocol.len)
  if u.startsWith("./"): u = c.workspace / u.substr(2)
  copyDir(selectDir(u & "@" & w.commit, u), destDir)
  writeFile destDir / ThisVersion, w.commit
  #echo "WRITTEN ", destDir / ThisVersion

proc isNewerVersion(a, b: string): bool =
  # only used for testing purposes.
  if a == InvalidCommit or b == InvalidCommit:
    return true
  var amajor, aminor, apatch, bmajor, bminor, bpatch: int
  if scanf(a, "$i.$i.$i", amajor, aminor, apatch):
    assert scanf(b, "$i.$i.$i", bmajor, bminor, bpatch)
    result = (amajor, aminor, apatch) > (bmajor, bminor, bpatch)
  else:
    assert scanf(a, "$i.$i", amajor, aminor)
    assert scanf(b, "$i.$i", bmajor, bminor)
    result = (amajor, aminor) > (bmajor, bminor)

proc isLaterCommit(destDir, version: string): bool =
  let oldVersion = try: readFile(destDir / ThisVersion).strip: except: "0.0"
  result = isNewerVersion(version, oldVersion)

proc traverseLoop(c: var AtlasContext; g: var DepGraph; startIsDep: bool): seq[CfgPath] =
  if c.lockMode == useLock:
    let lockFilePath = dependencyDir(c, g.nodes[0]) / LockFileName
    c.lockFile = readLockFile(lockFilePath)

  result = @[]
  var i = 0
  while i < g.nodes.len:
    let w = g.nodes[i]
    let destDir = toDestDir(w.name)
    let oldErrors = c.errors

    if not dirExists(c.workspace / destDir) and not dirExists(c.depsDir / destDir):
      withDir c, (if i != 0 or startIsDep: c.depsDir else: c.workspace):
        if w.url.startsWith(FileProtocol):
          copyFromDisk c, w
        else:
          let err = cloneUrl(c, w.url, destDir, false)
          if err != "":
            error c, w.name, err
    # assume this is the selected version, it might get overwritten later:
    selectNode c, g, w
    if oldErrors == c.errors:
      if KeepCommits notin c.flags:
        if not w.url.startsWith(FileProtocol):
          checkoutCommit(c, g, w)
        else:
          withDir c, (if i != 0 or startIsDep: c.depsDir else: c.workspace):
            if isLaterCommit(destDir, w.commit):
              copyFromDisk c, w
              selectNode c, g, w
      # even if the checkout fails, we can make use of the somewhat
      # outdated .nimble file to clone more of the most likely still relevant
      # dependencies:
      result.addUnique collectNewDeps(c, g, i, w)
    inc i

  if c.lockMode == genLock:
    writeFile c.currentDir / LockFileName, toJson(c.lockFile).pretty

proc traverse(c: var AtlasContext; start: string; startIsDep: bool): seq[CfgPath] =
  # returns the list of paths for the nim.cfg file.
  let url = toUrl(c, start)
  var g = DepGraph(nodes: @[Dependency(name: toName(start), url: url, commit: "", self: 0)])
  g.byName.mgetOrPut(toName(start), @[]).add 0

  if url == "":
    error c, toName(start), "cannot resolve package name"
    return

  c.projectDir = c.workspace / toDestDir(g.nodes[0].name)
  result = traverseLoop(c, g, startIsDep)
  afterGraphActions c, g

const
  configPatternBegin = "############# begin Atlas config section ##########\n"
  configPatternEnd =   "############# end Atlas config section   ##########\n"

proc patchNimCfg(c: var AtlasContext; deps: seq[CfgPath]; cfgPath: string) =
  var paths = "--noNimblePath\n"
  for d in deps:
    let pkgname = toDestDir d.string.PackageName
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
    assert cfgPath.len > 0
    if cfgPath.len > 0 and not dirExists(cfgPath):
      error(c, c.projectDir.PackageName, "could not write the nim.cfg")
    elif not fileExists(cfg):
      writeFile(cfg, cfgContent)
      info(c, projectFromCurrentDir(), "created: " & cfg.readableFile)
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
        info(c, projectFromCurrentDir(), "updated: " & cfg.readableFile)

proc fatal*(msg: string) =
  when defined(debug):
    writeStackTrace()
  quit "[Error] " & msg

proc findSrcDir(c: var AtlasContext): string =
  for nimbleFile in walkPattern(c.currentDir / "*.nimble"):
    let nimbleInfo = extractRequiresInfo(c, nimbleFile)
    return c.currentDir / nimbleInfo.srcDir
  return c.currentDir

proc installDependencies(c: var AtlasContext; nimbleFile: string; startIsDep: bool) =
  # 1. find .nimble file in CWD
  # 2. install deps from .nimble
  var g = DepGraph(nodes: @[])
  let (_, pkgname, _) = splitFile(nimbleFile)
  let dep = Dependency(name: toName(pkgname), url: "", commit: "", self: 0)
  discard collectDeps(c, g, -1, dep, nimbleFile)
  let paths = traverseLoop(c, g, startIsDep)
  patchNimCfg(c, paths, if CfgHere in c.flags: c.currentDir else: findSrcDir(c))
  afterGraphActions c, g

proc updateDir(c: var AtlasContext; dir, filter: string) =
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
                info(c, pkg, "successfully updated")
            else:
              error c, pkg, "could not fetch current branch name"

proc patchNimbleFile(c: var AtlasContext; dep: string): string =
  let thisProject = c.currentDir.splitPath.tail
  let oldErrors = c.errors
  let url = toUrl(c, dep)
  result = ""
  if oldErrors != c.errors:
    warn c, toName(dep), "cannot resolve package name"
  else:
    for x in walkFiles(c.currentDir / "*.nimble"):
      if result.len == 0:
        result = x
      else:
        # ambiguous .nimble file
        warn c, toName(dep), "cannot determine `.nimble` file; there are multiple to choose from"
        return ""
    # see if we have this requirement already listed. If so, do nothing:
    var found = false
    if result.len > 0:
      let nimbleInfo = extractRequiresInfo(c, result)
      for r in nimbleInfo.requires:
        var tokens: seq[string] = @[]
        for token in tokenizeRequires(r):
          tokens.add token
        if tokens.len > 0:
          let oldErrors = c.errors
          let urlB = toUrl(c, tokens[0])
          if oldErrors != c.errors:
            warn c, toName(tokens[0]), "cannot resolve package name; found in: " & result
          if url == urlB:
            found = true
            break

    if not found:
      let line = "requires \"$1\"\n" % dep.escape("", "")
      if result.len > 0:
        let oldContent = readFile(result)
        writeFile result, oldContent & "\n" & line
        info(c, toName(thisProject), "updated: " & result.readableFile)
      else:
        result = c.currentDir / thisProject & ".nimble"
        writeFile result, line
        info(c, toName(thisProject), "created: " & result.readableFile)
    else:
      info(c, toName(thisProject), "up to date: " & result.readableFile)

proc detectWorkspace(currentDir: string): string =
  result = currentDir
  while result.len > 0:
    if fileExists(result / AtlasWorkspace):
      return result
    result = result.parentDir()

proc absoluteDepsDir(workspace, value: string): string =
  if value == ".":
    result = workspace
  elif isAbsolute(value):
    result = value
  else:
    result = workspace / value

proc autoWorkspace(currentDir: string): string =
  result = currentDir
  while result.len > 0 and dirExists(result / ".git"):
    result = result.parentDir()

proc createWorkspaceIn(workspace, depsDir: string) =
  if not fileExists(workspace / AtlasWorkspace):
    writeFile workspace / AtlasWorkspace, "deps=\"$#\"" % escape(depsDir, "", "")
  createDir absoluteDepsDir(workspace, depsDir)

proc parseOverridesFile(c: var AtlasContext; filename: string) =
  const Separator = " -> "
  let path = c.workspace / filename
  var f: File
  if open(f, path):
    c.flags.incl UsesOverrides
    try:
      var lineCount = 1
      for line in lines(path):
        let splitPos = line.find(Separator)
        if splitPos >= 0 and line[0] != '#':
          let key = line.substr(0, splitPos-1)
          let val = line.substr(splitPos+len(Separator))
          if key.len == 0 or val.len == 0:
            error c, toName(path), "key/value must not be empty"
          let err = c.overrides.addPattern(key, val)
          if err.len > 0:
            error c, toName(path), "(" & $lineCount & "): " & err
        else:
          discard "ignore the line"
        inc lineCount
    finally:
      close f
  else:
    error c, toName(path), "cannot open: " & path

proc readConfig(c: var AtlasContext) =
  let configFile = c.workspace / AtlasWorkspace
  var f = newFileStream(configFile, fmRead)
  if f == nil:
    error c, toName(configFile), "cannot open: " & configFile
    return
  var p: CfgParser
  open(p, f, configFile)
  while true:
    var e = next(p)
    case e.kind
    of cfgEof: break
    of cfgSectionStart:
      discard "who cares about sections"
    of cfgKeyValuePair:
      case e.key.normalize
      of "deps":
        c.depsDir = absoluteDepsDir(c.workspace, e.value)
      of "overrides":
        parseOverridesFile(c, e.value)
      else:
        warn c, toName(configFile), "ignored unknown setting: " & e.key
    of cfgOption:
      discard "who cares about options"
    of cfgError:
      error c, toName(configFile), e.msg
  close(p)

const
  BatchFile = """
@echo off
set PATH="$1";%PATH%
"""
  ShellFile = "export PATH=$1:$$PATH\n"

const
  ActivationFile = when defined(windows): "activate.bat" else: "activate.sh"

proc infoAboutActivation(c: var AtlasContext; nimDest, nimVersion: string) =
  when defined(windows):
    info c, toName(nimDest), "RUN\nnim-" & nimVersion & "\\activate.bat"
  else:
    info c, toName(nimDest), "RUN\nsource nim-" & nimVersion & "/activate.sh"

proc setupNimEnv(c: var AtlasContext; nimVersion: string) =
  template isDevel(nimVersion: string): bool = nimVersion == "devel"

  template exec(c: var AtlasContext; command: string) =
    let cmd = command # eval once
    if os.execShellCmd(cmd) != 0:
      error c, toName("nim-" & nimVersion), "failed: " & cmd
      return

  let nimDest = "nim-" & nimVersion
  if dirExists(c.workspace / nimDest):
    if not fileExists(c.workspace / nimDest / ActivationFile):
      info c, toName(nimDest), "already exists; remove or rename and try again"
    else:
      infoAboutActivation c, nimDest, nimVersion
    return

  var major, minor, patch: int
  if nimVersion != "devel":
    if not scanf(nimVersion, "$i.$i.$i", major, minor, patch):
      error c, toName("nim"), "cannot parse version requirement"
      return
  let csourcesVersion =
    if nimVersion.isDevel or (major == 1 and minor >= 9) or major >= 2:
      # already uses csources_v2
      "csources_v2"
    elif major == 0:
      "csources" # has some chance of working
    else:
      "csources_v1"
  withDir c, c.workspace:
    if not dirExists(csourcesVersion):
      exec c, "git clone https://github.com/nim-lang/" & csourcesVersion
    exec c, "git clone https://github.com/nim-lang/nim " & nimDest
  withDir c, c.workspace / csourcesVersion:
    when defined(windows):
      exec c, "build.bat"
    else:
      let makeExe = findExe("make")
      if makeExe.len == 0:
        exec c, "sh build.sh"
      else:
        exec c, "make"
  let nimExe0 = ".." / csourcesVersion / "bin" / "nim".addFileExt(ExeExt)
  withDir c, c.workspace / nimDest:
    let nimExe = "bin" / "nim".addFileExt(ExeExt)
    copyFileWithPermissions nimExe0, nimExe
    let dep = Dependency(name: toName(nimDest), rel: normal, commit: nimVersion, self: 0)
    if not nimVersion.isDevel:
      let commit = versionToCommit(c, dep)
      if commit.len == 0:
        error c, toName(nimDest), "cannot resolve version to a commit"
        return
      checkoutGitCommit(c, dep.name, commit)
    exec c, nimExe & " c --noNimblePath --skipUserCfg --skipParentCfg --hints:off koch"
    let kochExe = when defined(windows): "koch.exe" else: "./koch"
    exec c, kochExe & " boot -d:release --skipUserCfg --skipParentCfg --hints:off"
    exec c, kochExe & " tools --skipUserCfg --skipParentCfg --hints:off"
    # remove any old atlas binary that we now would end up using:
    if cmpPaths(getAppDir(), c.workspace / nimDest / "bin") != 0:
      removeFile "bin" / "atlas".addFileExt(ExeExt)
    # unless --keep is used delete the csources because it takes up about 2GB and
    # is not necessary afterwards:
    if Keep notin c.flags:
      removeDir c.workspace / csourcesVersion / "c_code"
    let pathEntry = (c.workspace / nimDest / "bin")
    when defined(windows):
      writeFile "activate.bat", BatchFile % pathEntry.replace('/', '\\')
    else:
      writeFile "activate.sh", ShellFile % pathEntry
    infoAboutActivation c, nimDest, nimVersion

proc extractVersion(s: string): string =
  var i = 0
  while i < s.len and s[i] notin {'0'..'9'}: inc i
  result = s.substr(i)

proc listOutdated(c: var AtlasContext; dir: string) =
  var updateable = 0
  for k, f in walkDir(dir, relative=true):
    if k in {pcDir, pcLinkToDir} and dirExists(dir / f / ".git"):
      withDir c, dir / f:
        let (outp, status) = silentExec("git fetch", [])
        if status == 0:
          let (cc, status) = exec(c, GitLastTaggedRef, [])
          let latestVersion = strutils.strip(cc)
          if status == 0 and latestVersion.len > 0:
            # see if we're past that commit:
            let (cc, status) = exec(c, GitCurrentCommit, [])
            if status == 0:
              let currentCommit = strutils.strip(cc)
              if currentCommit != latestVersion:
                # checkout the later commit:
                # git merge-base --is-ancestor <commit> <commit>
                let (cc, status) = exec(c, GitMergeBase, [currentCommit, latestVersion])
                let mergeBase = strutils.strip(cc)
                #echo f, " I'm at ", currentCommit, " release is at ", latestVersion, " merge base is ", mergeBase
                if status == 0 and mergeBase == currentCommit:
                  let v = extractVersion gitDescribeRefTag(c, latestVersion)
                  if v.len > 0:
                    info c, toName(f), "new version available: " & v
                    inc updateable
        else:
          warn c, toName(f), "`git fetch` failed: " & outp
  if updateable == 0:
    info c, toName(c.workspace), "all packages are up to date"

proc listOutdated(c: var AtlasContext) =
  if c.depsDir.len > 0 and c.depsDir != c.workspace:
    listOutdated c, c.depsDir
  listOutdated c, c.workspace

proc main =
  var action = ""
  var args: seq[string] = @[]
  template singleArg() =
    if args.len != 1:
      fatal action & " command takes a single package name"

  template noArgs() =
    if args.len != 0:
      fatal action & " command takes no arguments"

  template projectCmd() =
    if c.projectDir == c.workspace or c.projectDir == c.depsDir:
      fatal action & " command must be executed in a project, not in the workspace"

  var c = AtlasContext(projectDir: getCurrentDir(), currentDir: getCurrentDir(), workspace: "")
  var autoinit = false
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
      of "keepcommits": c.flags.incl KeepCommits
      of "workspace":
        if val == ".":
          c.workspace = getCurrentDir()
          createWorkspaceIn c.workspace, c.depsDir
        elif val.len > 0:
          c.workspace = val
          createDir(val)
          createWorkspaceIn c.workspace, c.depsDir
        else:
          writeHelp()
      of "project":
        if isAbsolute(val):
          c.currentDir = val
        else:
          c.currentDir = getCurrentDir() / val
      of "deps":
        if val.len > 0:
          c.depsDir = val
        else:
          writeHelp()
      of "cfghere": c.flags.incl CfgHere
      of "autoinit": autoinit = true
      of "showgraph": c.flags.incl ShowGraph
      of "keep": c.flags.incl Keep
      of "autoenv": c.flags.incl AutoEnv
      of "genlock":
        if c.lockMode != useLock:
          c.lockMode = genLock
        else:
          writeHelp()
      of "uselock":
        if c.lockMode != genLock:
          c.lockMode = useLock
        else:
          writeHelp()
      of "colors":
        case val.normalize
        of "off": c.flags.incl NoColors
        of "on": c.flags.excl NoColors
        else: writeHelp()
      else: writeHelp()
    of cmdEnd: assert false, "cannot happen"

  if c.workspace.len > 0:
    if not dirExists(c.workspace): fatal "Workspace directory '" & c.workspace & "' not found."
  elif action != "init":
    when MockupRun:
      c.workspace = autoWorkspace(c.currentDir)
    else:
      c.workspace = detectWorkspace(c.currentDir)
      if c.workspace.len > 0:
        readConfig c
        info c, toName(c.workspace.readableFile), "is the current workspace"
      elif autoinit:
        c.workspace = autoWorkspace(c.currentDir)
        createWorkspaceIn c.workspace, c.depsDir
      elif action notin ["search", "list"]:
        fatal "No workspace found. Run `atlas init` if you want this current directory to be your workspace."

  when MockupRun:
    c.depsDir = c.workspace

  case action
  of "":
    fatal "No action."
  of "init":
    c.workspace = getCurrentDir()
    createWorkspaceIn c.workspace, c.depsDir
  of "clone", "update":
    singleArg()
    let deps = traverse(c, args[0], startIsDep = false)
    patchNimCfg c, deps, if CfgHere in c.flags: c.currentDir else: findSrcDir(c)
    when MockupRun:
      if not c.mockupSuccess:
        fatal "There were problems."
    else:
      if c.errors > 0:
        fatal "There were problems."
  of "use":
    projectCmd()
    singleArg()
    let nimbleFile = patchNimbleFile(c, args[0])
    if nimbleFile.len > 0:
      installDependencies(c, nimbleFile, startIsDep = false)
  of "install":
    projectCmd()
    if args.len > 1:
      fatal "install command takes a single argument"
    var nimbleFile = ""
    if args.len == 1:
      nimbleFile = args[0]
    else:
      for x in walkPattern("*.nimble"):
        nimbleFile = x
        break
    if nimbleFile.len == 0:
      fatal "could not find a .nimble file"
    else:
      installDependencies(c, nimbleFile, startIsDep = true)
  of "refresh":
    noArgs()
    updatePackages(c)
  of "search", "list":
    if c.workspace.len != 0:
      updatePackages(c)
      search getPackages(c.workspace), args
    else: search @[], args
  of "updateprojects":
    updateDir(c, c.workspace, if args.len == 0: "" else: args[0])
  of "updatedeps":
    updateDir(c, c.depsDir, if args.len == 0: "" else: args[0])
  of "extract":
    singleArg()
    if fileExists(args[0]):
      echo toJson(extractRequiresInfo(args[0]))
    else:
      fatal "File does not exist: " & args[0]
  of "tag":
    projectCmd()
    if args.len == 0:
      tag(c, ord(patch))
    elif args[0].len == 1 and args[0][0] in {'a'..'z'}:
      let field = ord(args[0][0]) - ord('a')
      tag(c, field)
    elif args[0].len == 1 and args[0][0] in {'A'..'Z'}:
      let field = ord(args[0][0]) - ord('A')
      tag(c, field)
    elif '.' in args[0]:
      tag(c, args[0])
    else:
      var field: SemVerField
      try: field = parseEnum[SemVerField](args[0])
      except: fatal "tag command takes one of 'patch' 'minor' 'major', a SemVer tag, or a letter from 'a' to 'z'"
      tag(c, ord(field))
  of "build", "test", "doc", "tasks":
    projectCmd()
    nimbleExec(action, args)
  of "task":
    projectCmd()
    nimbleExec("", args)
  of "env":
    singleArg()
    setupNimEnv c, args[0]
  of "outdated":
    listOutdated(c)
  else:
    fatal "Invalid action: " & action

when isMainModule:
  main()
