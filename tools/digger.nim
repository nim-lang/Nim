#[

## notes
can build as far back as: v0.12.0~157
]#

import std/[os, osproc, strformat, macros, strutils, tables, algorithm]
import timn/dbgs

type
  CsourcesOpt = ref object
    url: string
    dir: string
    rev: string
    binDir: string
    csourcesBuildArgs: string
    revs: seq[string]
    fetch: bool
    name: string
    nimCsourcesExe: string
  DiggerOpt = object
    # input fields
    rev: string
    nimDir: string
    compileNim: bool
    fetch: bool
    csourcesBuildArgs: string
    buildAllCsources: bool
    verbose: bool

    # bisect cmds
    # TODO: specify whether we should compile nim
    bisectCmd: string
    bisectBugfix: bool
    oldrev, newrev: string

    # state fieles (TODO: split out these)
    coptv0: CsourcesOpt
    coptv1: CsourcesOpt
    binDir: string

const
  nimUrl = "https://github.com/nim-lang/Nim"
  csourcesUrl = "https://github.com/nim-lang/csources.git"
  csourcesV1Url = "https://github.com/nim-lang/csources_v1.git"
  csourcesName = "csources"
  csourcesV1Name = "csources_v1"
  csourcesRevs = "v0.9.4 v0.13.0 v0.15.2 v0.16.0 v0.17.0 v0.17.2 v0.18.0 v0.19.0 v0.20.0 64e3477".split
  csourcesV1Revs = "a8a5241f9475099c823cfe1a5e0ca4022ac201ff".split
  NimDiggerEnv = "NIMDIGGER_HOME"

var verbose = false
proc isSimulate(): bool =
  defined(nimDiggerSimulate)

proc runCmd(cmd: string) =
  # TODO: allow `dir` param
  if isSimulate():
    dbg cmd
  else:
    if verbose: dbg cmd
    doAssert execShellCmd(cmd) == 0, cmd

proc runCmdOutput(cmd: string, dir = ""): string =
  if verbose: dbg cmd, dir
  let (outp, status) = execCmdEx(cmd, workingDir = dir)
  doAssert status == 0, &"status: {status}\ncmd: {cmd}\ndir: {dir}\noutput: {outp}"
  result = outp
  stripLineEnd(result)

macro ctor(obj: untyped, a: varargs[untyped]): untyped =
  ## Generates an object constructor call from a list of fields.
  # xxx expose in some `fusion/macros` or std/macros; FACTOR with pr_fusion_globs PR
  runnableExamples:
    type Foo = object
      a, b: int
    doAssert Foo.ctor(a,b) == Foo(a: a, b: b)
  result = nnkObjConstr.newTree(obj)
  for ai in a: result.add nnkExprColonExpr.newTree(ai, ai)

proc gitClone(url: string, dir: string) = runCmd fmt"git clone -q {url} {dir.quoteShell}"
proc gitResetHard(dir: string, rev: string) = runCmd fmt"git -C {dir.quoteShell} reset --hard {rev}"
proc gitFetch(dir: string) = runCmd fmt"git -C {dir.quoteShell} fetch"
proc gitLatestTag(dir: string): string = runCmdOutput("git describe --abbrev=0 HEAD", dir)
proc gitCheck(dir: string) =
  # checks whether we're in a valid git repo; there may be better ways
  discard runCmdOutput("git describe HEAD", dir)

proc gitIsAncestorOf(dir: string, rev1, rev2: string): bool =
  gitCheck(dir)
  execShellCmd(fmt"git -C {dir.quoteShell} merge-base --is-ancestor {rev1} {rev2}") == 0

proc isGitNimTag(tag: string): bool =
  if not tag.startsWith "v":
    return false
  let ver = tag[1..^1].split(".")
  return ver.len == 3

proc parseNimGitTag(tag: string): (int, int, int) =
  doAssert tag.isGitNimTag, tag
  let ver = tag[1..^1].split(".")
  template impl(i) =
    # improve pending https://github.com/nim-lang/Nim/pull/18038
    result[i] = ver[i].parseInt
  impl 0
  impl 1
  impl 2

proc toNimCsourcesExe(binDir: string, name: string, rev: string): string =
  let rev2 = rev.replace(".", "_")
  result = binDir / fmt"nim_digger_{name}_{rev2}"

proc buildCsourcesRev(copt: CsourcesOpt) =
  # sync with `_nimBuildCsourcesIfNeeded`
  let csourcesExe = toNimCsourcesExe(copt.binDir, copt.name, copt.rev)
  if csourcesExe.fileExists:
    return
  if verbose: dbg copt
  if not copt.dir.dirExists: gitClone(copt.url, copt.dir)
  if copt.fetch: gitFetch(copt.dir)
  gitResetHard(copt.dir, copt.rev)
  when defined(bsd):
    let make = "gmake"
  else:
    let make = "make"
  let ncpu = countProcessors()
  if copt.rev.isGitNimTag and copt.rev.parseNimGitTag < (0,15,2):
    # avoids: make: *** No rule to make target `c_code/3_2/compiler_testability.o', needed by `../bin/nim'.  Stop.
    discard runCmdOutput(fmt"sh build.sh {copt.csourcesBuildArgs}", copt.dir)
  else:
    discard runCmdOutput(fmt"{make} -j {ncpu + 2} -l {ncpu} {copt.csourcesBuildArgs}", copt.dir)
  if isSimulate():
    dbg csourcesExe
  else:
    copyFile(copt.binDir / "nim", csourcesExe) # TODO: windows exe etc?

proc buildCsourcesAnyRevs(copt: CsourcesOpt) =
  for rev in copt.revs:
    copt.rev = rev
    buildCsourcesRev(copt)

proc parseKeyVal(a: string): OrderedTable[string, string] =
  ## parse bash-like entries of the form key=val
  let a2 = a.splitLines
  for i, ai in a2:
    if ai.len == 0 or ai.startsWith "#": continue
    let b = split(ai, "=", maxsplit = 1)
    doAssert b.len == 2, $(ai, b)
    result[b[0]] = b[1]

proc toCsourcesRev(rev: string): string =
  let ver = rev.parseNimGitTag
  if ver >= (1, 0, 0): return csourcesRevs[^1]
  for a in csourcesRevs[1 ..< ^1].reversed:
    if ver >= a.parseNimGitTag: return a
  # v0.9.4 seems broken
  return csourcesRevs[1]

proc getNimCsourcesAnyExe(opt: DiggerOpt): CsourcesOpt =
  let file = opt.nimDir/"config/build_config.txt" # for newer nim versions, this file specifies correct csources_v1 to use
  if file.fileExists:
    let tab = file.readFile.parseKeyVal
    result = opt.coptv1
    result.rev = tab["nim_csourcesHash"]
  elif gitIsAncestorOf(opt.nimDir, "a9b62de", opt.rev): # commit that introduced csources_v1
    result = opt.coptv1
    result.rev = csourcesV1Revs[0]
  else:
    let tag = gitLatestTag(opt.nimDir)
    result = opt.coptv0
    result.rev = tag.toCsourcesRev
  result.nimCsourcesExe = toNimCsourcesExe(opt.binDir, result.name, result.rev)

proc main2(opt: DiggerOpt) =
  var opt = opt
  let nimdiggerHome = getEnv(NimDiggerEnv, getHomeDir() / ".nimdigger")
  if opt.nimDir.len == 0:
    opt.nimDir = nimdiggerHome / "cache/Nim"
  if verbose: dbg opt
  let nimDir = opt.nimDir
  let csourcesDir = nimDir/csourcesName
  let csourcesV1Dir = nimDir/csourcesV1Name
  opt.binDir = nimDir/"bin"
  let nimDiggerExe = opt.binDir / "nim_digger"

  if nimDir.dirExists:
    doAssert fileExists(nimDir / "lib/system.nim"), fmt"nimDir is not a nim repo: {nimDir}"
  else:
    createDir nimDir.parentDir
    gitClone(nimUrl, nimDir)

  opt.coptv0 = CsourcesOpt(dir: csourcesDir, url: csourcesUrl, name: csourcesName, revs: csourcesRevs)
  opt.coptv1 = CsourcesOpt(dir: csourcesV1Dir, url: csourcesV1Url, name: csourcesV1Name, revs: csourcesV1Revs)
  for copt in [opt.coptv0, opt.coptv1]:
    copt.binDir = opt.binDir
    copt.fetch = opt.fetch
    if opt.buildAllCsources:
      buildCsourcesAnyRevs(copt)

  if opt.fetch: gitFetch(nimDir)
  if opt.rev.len > 0: gitResetHard(nimDir, opt.rev)
  else: opt.rev = "HEAD"

  if opt.compileNim:
    let copt = getNimCsourcesAnyExe(opt)
    buildCsourcesRev(copt)
    # TODO: we could also cache those, optionally maybe (could get large?) or use this as hint in nim bisect to prefer those
    discard runCmdOutput(fmt"{copt.nimCsourcesExe} c -o:{nimDiggerExe} --hints:off --skipUserCfg compiler/nim.nim", nimDir)

  if opt.bisectCmd.len > 0:
    doAssert opt.oldrev.len > 0 # for regressions, aka goodrev
    doAssert opt.newrev.len > 0 # for a regressions, aka badrev 
    runCmd(fmt"git -C {opt.nimDir.quoteShell} bisect start {opt.newrev} {opt.oldrev}")
    let exe = getAppFileName()
    var msg2 = opt.bisectCmd
    if opt.bisectBugfix:
      msg2 = fmt"! ({msg2})" # negate exit code
    let bisectCmd2 = fmt"{exe} --compileNim && cp {nimDiggerExe.quoteShell} bin/nim && {msg2}"
    runCmd(fmt"git -C {opt.nimDir.quoteShell} bisect run bash -c {bisectCmd2.quoteShell}")

proc main(rev = "", nimDir = "", compileNim = false, fetch = false, bisectCmd = "", newrev = "", oldrev = "", bisectBugfix = false, verbose = false) =
  digger.verbose = verbose
  main2(DiggerOpt.ctor(rev, nimDir, compileNim, fetch, bisectCmd, newrev, oldrev, bisectBugfix))

when isMainModule:
  import pkg/cligen
  dispatch main
