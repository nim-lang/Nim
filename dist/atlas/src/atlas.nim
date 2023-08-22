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
  hashes, options]
import context, runners, osutils, packagesjson, sat, gitops, nimenv, lockfiles,
  traversal, confighandler, nameresolver

export osutils, context

const
  AtlasVersion = "0.6.2"
  LockFileName = "atlas.lock"
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
  pin [atlas.lock]      pin the current checkouts and store them in the lock
  rep [atlas.lock]      replay the state of the projects according to the lock
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
  --noexec              do not perform any action that may run arbitrary code
  --autoenv             detect the minimal Nim $version and setup a
                        corresponding Nim virtual environment
  --autoinit            auto initialize a workspace
  --colors=on|off       turn on|off colored output
  --resolver=minver|semver|maxver
                        which resolution algorithm to use, default is minver
  --showGraph           show the dependency graph
  --list                list all available and installed versions
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


include testdata

proc tag(c: var AtlasContext; tag: string) =
  gitTag(c, tag)
  pushTag(c, tag)

proc tag(c: var AtlasContext; field: Natural) =
  let oldErrors = c.errors
  let newTag = incrementLastTag(c, field)
  if c.errors == oldErrors:
    tag(c, newTag)

proc generateDepGraph(c: var AtlasContext; g: DepGraph) =
  proc repr(w: Dependency): string =
    $(w.url / w.commit)

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

proc afterGraphActions(c: var AtlasContext; g: DepGraph) =
  if ShowGraph in c.flags:
    generateDepGraph c, g
  if AutoEnv in c.flags and g.bestNimVersion != Version"":
    setupNimEnv c, g.bestNimVersion.string

const
  FileProtocol = "file"
  ThisVersion = "current_version.atlas"

proc checkoutCommit(c: var AtlasContext; g: var DepGraph; w: Dependency) =
  let dir = dependencyDir(c, w)
  withDir c, dir:
    if w.commit.len == 0 or cmpIgnoreCase(w.commit, "head") == 0:
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

proc copyFromDisk(c: var AtlasContext; w: Dependency; destDir: string): (CloneStatus, string) =
  var u = w.url.getFilePath()
  if u.startsWith("./"): u = c.workspace / u.substr(2)
  let dir = selectDir(u & "@" & w.commit, u)
  if dirExists(dir):
    copyDir(dir, destDir)
    result = (Ok, "")
  else:
    result = (NotFound, dir)
  #writeFile destDir / ThisVersion, w.commit
  #echo "WRITTEN ", destDir / ThisVersion

proc isLaterCommit(destDir, version: string): bool =
  let oldVersion = try: readFile(destDir / ThisVersion).strip except: "0.0"
  if isValidVersion(oldVersion) and isValidVersion(version):
    result = Version(oldVersion) < Version(version)
  else:
    result = true

proc collectAvailableVersions(c: var AtlasContext; g: var DepGraph; w: Dependency) =
  when MockupRun:
    # don't cache when doing the MockupRun:
    g.availableVersions[w.name] = collectTaggedVersions(c)
  else:
    if not g.availableVersions.hasKey(w.name):
      g.availableVersions[w.name] = collectTaggedVersions(c)

proc toString(x: (string, string, Version)): string =
  "(" & x[0] & ", " & $x[2] & ")"

proc resolve(c: var AtlasContext; g: var DepGraph) =
  var b = sat.Builder()
  b.openOpr(AndForm)
  # Root must true:
  b.add newVar(VarId 0)

  assert g.nodes.len > 0
  #assert g.nodes[0].active # this does not have to be true if some
  # project is listed multiple times in the .nimble file.
  # Implications:
  for i in 0..<g.nodes.len:
    if g.nodes[i].active:
      for j in g.nodes[i].parents:
        # "parent has a dependency on x" is translated to:
        # "parent implies x" which is "not parent or x"
        if j >= 0:
          b.openOpr(OrForm)
          b.openOpr(NotForm)
          b.add newVar(VarId j)
          b.closeOpr
          b.add newVar(VarId i)
          b.closeOpr
    elif g.nodes[i].status == NotFound:
      # dependency produced an error and so cannot be 'true':
      b.openOpr(NotForm)
      b.add newVar(VarId i)
      b.closeOpr

  var idgen = 0
  var mapping: seq[(string, string, Version)] = @[]
  # Version selection:
  for i in 0..<g.nodes.len:
    let av = g.availableVersions.getOrDefault(g.nodes[i].name)
    if g.nodes[i].active and av.len > 0:
      let bpos = rememberPos(b)
      # A -> (exactly one of: A1, A2, A3)
      b.openOpr(OrForm)
      b.openOpr(NotForm)
      b.add newVar(VarId i)
      b.closeOpr
      b.openOpr(ExactlyOneOfForm)

      let oldIdgen = idgen
      var q = g.nodes[i].query
      if g.nodes[i].algo == SemVer: q = toSemVer(q)
      let commit = extractSpecificCommit(q)
      if commit.len > 0:
        var v = Version("#" & commit)
        for j in countup(0, av.len-1):
          if q.matches(av[j]):
            v = av[j][1]
            break
        mapping.add (g.nodes[i].name.string, commit, v)
        b.add newVar(VarId(idgen + g.nodes.len))
        inc idgen
      elif g.nodes[i].algo == MinVer:
        for j in countup(0, av.len-1):
          if q.matches(av[j]):
            mapping.add (g.nodes[i].name.string, av[j][0], av[j][1])
            b.add newVar(VarId(idgen + g.nodes.len))
            inc idgen
      else:
        for j in countdown(av.len-1, 0):
          if q.matches(av[j]):
            mapping.add (g.nodes[i].name.string, av[j][0], av[j][1])
            b.add newVar(VarId(idgen + g.nodes.len))
            inc idgen

      b.closeOpr # ExactlyOneOfForm
      b.closeOpr # OrForm
      if idgen == oldIdgen:
        b.rewind bpos
  b.closeOpr
  let f = toForm(b)
  var s = newSeq[BindingKind](idgen)
  when false:
    let L = g.nodes.len
    var nodes = newSeq[string]()
    for i in 0..<L: nodes.add g.nodes[i].name.string
    echo f$(proc (buf: var string; i: int) =
      if i < L:
        buf.add nodes[i]
      else:
        buf.add $mapping[i - L])
  if satisfiable(f, s):
    for i in g.nodes.len..<s.len:
      if s[i] == setToTrue:
        let destDir = mapping[i - g.nodes.len][0]
        let dir = selectDir(c.workspace / destDir, c.depsDir / destDir)
        withDir c, dir:
          checkoutGitCommit(c, toName(destDir), mapping[i - g.nodes.len][1])
    if NoExec notin c.flags:
      runBuildSteps(c, g)
      #echo f
    if ListVersions in c.flags:
      echo "selected:"
      for i in g.nodes.len..<s.len:
        if s[i] == setToTrue:
          echo "[x] ", toString mapping[i - g.nodes.len]
        else:
          echo "[ ] ", toString mapping[i - g.nodes.len]
  else:
    error c, toName(c.workspace), "version conflict; for more information use --showGraph"
    var usedVersions = initCountTable[string]()
    for i in g.nodes.len..<s.len:
      if s[i] == setToTrue:
        usedVersions.inc mapping[i - g.nodes.len][0]
    for i in g.nodes.len..<s.len:
      if s[i] == setToTrue:
        let counter = usedVersions.getOrDefault(mapping[i - g.nodes.len][0])
        if counter > 0:
          error c, toName(mapping[i - g.nodes.len][0]), $mapping[i - g.nodes.len][2] & " required"

proc traverseLoop(c: var AtlasContext; g: var DepGraph; startIsDep: bool): seq[CfgPath] =
  result = @[]
  var i = 0
  while i < g.nodes.len:
    let w = g.nodes[i]
    let destDir = toDestDir(w.name)
    let oldErrors = c.errors

    let dir = selectDir(c.workspace / destDir, c.depsDir / destDir)
    if not dirExists(dir):
      withDir c, (if i != 0 or startIsDep: c.depsDir else: c.workspace):
        let (status, err) =
          if w.url.scheme == FileProtocol:
            copyFromDisk(c, w, destDir)
          else:
            cloneUrl(c, w.url, destDir, false)
        g.nodes[i].status = status
        case status
        of NotFound:
          discard "setting the status is enough here"
        of OtherError:
          error c, w.name, err
        else:
          withDir c, destDir:
            collectAvailableVersions c, g, w
    else:
      withDir c, dir:
        collectAvailableVersions c, g, w

    # assume this is the selected version, it might get overwritten later:
    selectNode c, g, w
    if oldErrors == c.errors:
      if KeepCommits notin c.flags and w.algo == MinVer:
        checkoutCommit(c, g, w)
      # even if the checkout fails, we can make use of the somewhat
      # outdated .nimble file to clone more of the most likely still relevant
      # dependencies:
      result.addUnique collectNewDeps(c, g, i, w)
    inc i

  if g.availableVersions.len > 0:
    resolve c, g

proc traverse(c: var AtlasContext; start: string; startIsDep: bool): seq[CfgPath] =
  # returns the list of paths for the nim.cfg file.
  let url = resolveUrl(c, start)
  var g = createGraph(c, start, url)

  if $url == "":
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
  let dep = Dependency(name: toName(pkgname), url: getUrl "", commit: "", self: 0,
                       algo: c.defaultAlgo)
  g.byName.mgetOrPut(toName(pkgname), @[]).add 0
  discard collectDeps(c, g, -1, dep, nimbleFile)
  let paths = traverseLoop(c, g, startIsDep)
  patchNimCfg(c, paths, if CfgHere in c.flags: c.currentDir else: findSrcDir(c))
  afterGraphActions c, g

proc updateDir(c: var AtlasContext; dir, filter: string) =
  ## update the package's VCS
  for kind, file in walkDir(dir):
    if kind == pcDir and isGitDir(file):
      gitops.updateDir(c, file, filter)

proc patchNimbleFile(c: var AtlasContext; dep: string): string =
  let thisProject = c.currentDir.lastPathComponent
  let oldErrors = c.errors
  let url = resolveUrl(c, dep)
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
          let urlB = resolveUrl(c, tokens[0])
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

proc autoWorkspace(currentDir: string): string =
  result = currentDir
  while result.len > 0 and dirExists(result / ".git"):
    result = result.parentDir()

proc createWorkspaceIn(workspace, depsDir: string) =
  if not fileExists(workspace / AtlasWorkspace):
    writeFile workspace / AtlasWorkspace, "deps=\"$#\"\nresolver=\"MaxVer\"\n" % escape(depsDir, "", "")
  createDir absoluteDepsDir(workspace, depsDir)

proc listOutdated(c: var AtlasContext; dir: string) =
  var updateable = 0
  for k, f in walkDir(dir, relative=true):
    if k in {pcDir, pcLinkToDir} and isGitDir(dir / f):
      withDir c, dir / f:
        if gitops.isOutdated(c, f):
          inc updateable

  if updateable == 0:
    info c, toName(c.workspace), "all packages are up to date"

proc listOutdated(c: var AtlasContext) =
  if c.depsDir.len > 0 and c.depsDir != c.workspace:
    listOutdated c, c.depsDir
  listOutdated c, c.workspace

proc main(c: var AtlasContext) =
  var action = ""
  var args: seq[string] = @[]
  template singleArg() =
    if args.len != 1:
      fatal action & " command takes a single package name"

  template optSingleArg(default: string) =
    if args.len == 0:
      args.add default
    elif args.len != 1:
      fatal action & " command takes a single package name"

  template noArgs() =
    if args.len != 0:
      fatal action & " command takes no arguments"

  template projectCmd() =
    if c.projectDir == c.workspace or c.projectDir == c.depsDir:
      fatal action & " command must be executed in a project, not in the workspace"

  var autoinit = false
  var explicitProjectOverride = false
  var explicitDepsDirOverride = false
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
          if not explicitProjectOverride:
            c.currentDir = val
          createDir(val)
          createWorkspaceIn c.workspace, c.depsDir
        else:
          writeHelp()
      of "project":
        explicitProjectOverride = true
        if isAbsolute(val):
          c.currentDir = val
        else:
          c.currentDir = getCurrentDir() / val
      of "deps":
        if val.len > 0:
          c.depsDir = val
          explicitDepsDirOverride = true
        else:
          writeHelp()
      of "cfghere": c.flags.incl CfgHere
      of "autoinit": autoinit = true
      of "showgraph": c.flags.incl ShowGraph
      of "keep": c.flags.incl Keep
      of "autoenv": c.flags.incl AutoEnv
      of "noexec": c.flags.incl NoExec
      of "list": c.flags.incl ListVersions
      of "colors":
        case val.normalize
        of "off": c.flags.incl NoColors
        of "on": c.flags.excl NoColors
        else: writeHelp()
      of "resolver":
        try:
          c.defaultAlgo = parseEnum[ResolutionAlgorithm](val)
        except ValueError:
          quit "unknown resolver: " & val
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
        infoNow c, toName(c.workspace.readableFile), "is the current workspace"
      elif autoinit:
        c.workspace = autoWorkspace(c.currentDir)
        createWorkspaceIn c.workspace, c.depsDir
      elif action notin ["search", "list", "tag"]:
        fatal "No workspace found. Run `atlas init` if you want this current directory to be your workspace."

  when MockupRun:
    c.depsDir = c.workspace
  else:
    if not explicitDepsDirOverride and action != "init" and c.depsDir.len() == 0:
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
  of "use":
    singleArg()
    let nimbleFile = patchNimbleFile(c, args[0])
    if nimbleFile.len > 0:
      installDependencies(c, nimbleFile, startIsDep = false)
  of "pin":
    optSingleArg(LockFileName)
    if c.projectDir == c.workspace or c.projectDir == c.depsDir:
      pinWorkspace c, args[0]
    else:
      pinProject c, args[0]
  of "rep":
    optSingleArg(LockFileName)
    replay c, args[0]
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
    else:
      search @[], args
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

proc main =
  var c = AtlasContext(projectDir: getCurrentDir(), currentDir: getCurrentDir(), workspace: "")
  try:
    main(c)
  finally:
    writePendingMessages(c)
  if c.errors > 0:
    quit 1

when isMainModule:
  main()
