##[
`nimdigger` is a tool to build nim at any revision (including custom branches), taking
care of details such as figuring out automatically the correct csources/csources_v1 revision to use.

## design goals
* ease of use: 1 liner for running `git bisect` workflows, or to build nim at past revisions
* performance: via caching both csources built binaries, and intermediate nim binaries
* lazyness: build artifacts on demand
* go as far back as possible, currently oldest buildable nim version is v0.12.0~157

## examples
build at any revision >= v0.12.0~157
```bash
$ nim r tools/nimdigger.nim --compileNim --rev:v0.15.2~10
$ $NIMDIGGER_CACHE/Nim/bin/nim -v
Nim Compiler Version 0.15.2 (2021-05-28) [MacOSX: amd64] [...]
```

find a which commit introduced a regression
```bash
$ nim r tools/nimdigger.nim --oldnew:v0.19.0..v0.20.0 \
  --bisectCmd:'bin/nim -v | grep 0.19.0'
66c0f7c3fb214485ca6cfd799af6e50798fcdf6d is the first REGRESSION commit
```

find a which commit introduced a bugfix
```bash
$ nim r tools/nimdigger.nim --oldnew:v0.19.0..v0.20.0 --bisectBugfix \
  --bisectCmd:'bin/nim -v | grep 0.20.0'
be9c38d2659496f918fb39e129b9b5b055eafd88 is the first BUGFIX commit
```
Note that this is fast (e.g. 3s) if intermediate nim binaries have already been built/cached in prior runs.

find an actual regression, e.g. for https://github.com/nim-lang/Nim/issues/16376,
copy this snippet to /tmp/t16376.nim
```nim
type Matrix[T] = object
  data: T
proc randMatrix*[T](m, n: int, max: T): Matrix[T] = discard
proc randMatrix*[T](m, n: int, x: Slice[T]): Matrix[T] = discard
template randMatrix*[T](m, n: int): Matrix[T] = randMatrix[T](m, n, T(1.0))
let B = randMatrix[float32](20, 10)
```
```bash
$ nim r tools/nimdigger.nim --oldnew:v0.19.0..v0.20.0 -- \
  bin/nim c --hints:off --skipparentcfg --skipusercfg /tmp/t16376.nim
fd16875561634e3ef24072631cf85eeead6213f2 is the first REGRESSION commit
```

## notes
* this uses `git` (in particular `bisect`), `csources`, `csources_v`, `bash`, `make`/`gmake`
* Unstable API, subject to change
]##

#[
## TODO
allow a way to verify that oldnew revisions honor what's implied by bisectBugfix:true|false

## note
we should give exit code = 125 to commits where nim won't build, to skip over, see also:
https://stackoverflow.com/a/22592593/1426932 (Magic exit statuses)
> anything above 127 makes the bisection fail with something like:
> 125 is magic and makes the run be skipped with git bisect skip.
]#

import std/[os, osproc, strformat, macros, strutils, tables, algorithm]

proc `$`(a: ref): string =
  if a == nil: "nil" else: $a[]

template dbg(args: varargs[untyped]): untyped =
  # so users can swap in their own better logging until stdlib has one
  echo args

type
  DiggerOpt = object ## nimdigger input
    rev: string
    nimDir: string
    compileNim: bool
    fetch: bool
    csourcesBuildArgs: string
    buildAllCsources: bool
    verbose: bool

    # bisect cmds
    # TODO: allow user to not compile nim, for cases where it's not needed
    oldnew: string # eg: v0.20.0~10..v0.20.0
    bisectCmd: string # eg: bin/nim c --hints:off --skipparentcfg --skipusercfg $timn_D/tests/nim/all/t12329.nim 'arg1 bar' 'arg2'
    bisectBugfix: bool
  CsourcesState = ref object ## represents csources or csources_v1 repos
    url: string
    dir: string # e.g. /pathto/Nim/csources
    rev: string
    binDir: string
    csourcesBuildArgs: string ## extra args to build csources
    revs: seq[string]
    fetch: bool
    name: string
    nimCsourcesExe: string
  DiggerState = ref object ## nimdigger internal state
    nimDir: string # e.g.: /pathto/Nim
    binDir: string # e.g.: $nimDir/bin
    rev: string # e.g.: hash obtained from `git rev-parse HEAD`
    csourceV0, csourceV1: CsourcesState

const
  csourcesRevs = "v0.9.4 v0.13.0 v0.15.2 v0.16.0 v0.17.0 v0.17.2 v0.18.0 v0.19.0 v0.20.0".split &
    "64e34778fa7e114b4afc753c7845dee250584167"
  csourcesV1Revs = "a8a5241f9475099c823cfe1a5e0ca4022ac201ff".split
  NimDiggerEnv = "NIMDIGGER_CACHE"
  ExeExt2 = when ExeExt.len > 0: "." & ExeExt else: ""

var verbose = false

proc isSimulate(): bool =
  defined(nimDiggerSimulate)

proc runCmd(cmd: string) =
  # TODO: allow `dir` param (or use `runCmdOutput`)
  if isSimulate():
    dbg cmd
  else:
    if verbose: dbg cmd
    doAssert execShellCmd(cmd) == 0, cmd

proc runCmdOutput(cmd: string, dir = ""): string =
  if verbose: dbg cmd, dir
  let (outp, status) = execCmdEx(cmd, workingDir = dir)
  doAssert status == 0, indent(&"status: {status}\ncmd: {cmd}\ndir: {dir}\noutput: {outp}", 2)
  result = outp
  stripLineEnd(result)

macro construct(obj: untyped, a: varargs[untyped]): untyped =
  ## Generates an object constructor call from a list of fields.
  # xxx expose in std/sugar, factor with https://github.com/nim-lang/fusion/pull/32
  runnableExamples:
    type Foo = object
      a, b: int
    doAssert Foo.construct(a,b) == Foo(a: a, b: b)
  result = nnkObjConstr.newTree(obj)
  for ai in a: result.add nnkExprColonExpr.newTree(ai, ai)

proc parseKeyVal(a: string): OrderedTable[string, string] =
  ## parse bash-like entries of the form key=val
  for ai in a.splitLines:
    if ai.len == 0 or ai.startsWith "#": continue
    let kv = split(ai, "=", maxsplit = 1)
    doAssert kv.len == 2, $(ai, kv)
    result[kv[0]] = kv[1]

# xxx move some of these to std/private/gitutils.nim
proc gitClone(url: string, dir: string) = runCmd fmt"git clone -q {url.quoteShell} {dir.quoteShell}"
proc gitResetHard(dir: string, rev: string) = runCmd fmt"git -C {dir.quoteShell} reset --hard {rev}"
proc gitCleanDanger(dir: string, requireConfirmation = true) =
  #[
  This is needed to avoid `git bisect` aborting with this error: The following untracked working tree files would be overwritten by checkout.
  For example, this would happen in cases like this:
  ```
  cd $NIMDIGGER_CACHE/Nim
  git checkout abaa42fd8a239ea62ddb39f6f58c3180137d750c
  touch testament/testamenthtml.templ
  cd -
  nim r tools/nimdigger.nim --oldnew:v0.19.0..v0.20.0 --bisectCmd:'bin/nim -v | grep 0.19.0'
  ```
  so we handle cleaning untracked files via dry run (-n) followed by -f if user confirms.
  ]#
  let files = runCmdOutput fmt"git -C {dir.quoteShell} clean -n"
  if files.len > 0:
    var runClean = true
    if requireConfirmation:
      echo &"untracked files may prevent `git bisect` from working, `git -C {dir.quoteShell} clean -n` returned:\n{files}"
      echo fmt"enter `yes` to proceed with `git clean -f` in: {dir.quoteShell}"
      let answer = stdin.readLine()
      runClean = answer == "yes"
    if runClean:
      runCmd fmt"git -C {dir.quoteShell} clean -f"
proc gitFetch(dir: string) = runCmd fmt"git -C {dir.quoteShell} fetch"
proc gitLatestTag(dir: string): string = runCmdOutput("git describe --abbrev=0 HEAD", dir)
proc gitCurrentRev(dir: string): string = runCmdOutput("git rev-parse HEAD", dir)
proc gitCheck(dir: string) =
  # checks whether we're in a valid git repo; there may be better ways
  discard runCmdOutput("git describe HEAD", dir)

proc gitIsAncestorOf(dir: string, rev1, rev2: string): bool =
  gitCheck(dir)
  execShellCmd(fmt"git -C {dir.quoteShell} merge-base --is-ancestor {rev1} {rev2}") == 0

import std/strscans

proc parseNimGitTag(tag: string): (int, int, int) =
  if not scanf(tag, "v$i.$i.$i$.", result[0], result[1], result[2]):
    raise newException(ValueError, tag)

proc isGitNimTag(tag: string): bool =
  try:
    discard parseNimGitTag(tag)
    return true
  except ValueError:
    return false

proc toNimCsourcesExe(binDir: string, name: string, rev: string): string =
  let rev2 = rev.replace(".", "_")
  result = binDir / fmt"nim_nimdigger_{name}_{rev2}{ExeExt2}"

proc buildCsourcesRev(copt: CsourcesState) =
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
  let oldNim = copt.binDir / "nim" & ExeExt2
  removeFile(oldNim) # otherwise `make` may incorrectly decide there's notthing to build
  let ncpu = countProcessors()
  if copt.rev.isGitNimTag and copt.rev.parseNimGitTag < (0,15,2):
    # avoids: make: *** No rule to make target `c_code/3_2/compiler_testability.o', needed by `../bin/nim'.  Stop.
    discard runCmdOutput(fmt"sh build.sh {copt.csourcesBuildArgs}", copt.dir)
  else:
    discard runCmdOutput(fmt"{make} -j {ncpu + 2} -l {ncpu} {copt.csourcesBuildArgs}", copt.dir)
  if isSimulate():
    dbg csourcesExe
  else:
    copyFile(oldNim, csourcesExe)

proc buildCsourcesAnyRevs(copt: CsourcesState) =
  for rev in copt.revs:
    copt.rev = rev
    buildCsourcesRev(copt)

proc toCsourcesRev(rev: string): string =
  let ver = rev.parseNimGitTag
  if ver >= (1, 0, 0): return csourcesRevs[^1]
  for a in csourcesRevs[1 ..< ^1].reversed:
    if ver >= a.parseNimGitTag: return a
  return csourcesRevs[1] # because v0.9.4 seems broken

proc getCsourcesState(state: DiggerState): CsourcesState =
  let file = state.nimDir/"config/build_config.txt" # for newer nim versions, this file specifies correct csources_v1 to use
  if file.fileExists:
    let tab = file.readFile.parseKeyVal
    result = state.csourceV1
    result.rev = tab["nim_csourcesHash"]
  elif gitIsAncestorOf(state.nimDir, "a9b62de", state.rev): # commit that introduced csources_v1
    result = state.csourceV1
    result.rev = csourcesV1Revs[0]
  else:
    let tag = gitLatestTag(state.nimDir)
    result = state.csourceV0
    result.rev = tag.toCsourcesRev
  result.nimCsourcesExe = toNimCsourcesExe(state.binDir, result.name, result.rev)

proc main2(opt: DiggerOpt) =
  let state = DiggerState(nimDir: opt.nimDir, rev: opt.rev)
  if state.nimDir.len == 0:
    let nimdiggerCache = getEnv(NimDiggerEnv, getCacheDir("nimdigger"))
    state.nimDir = nimdiggerCache / "Nim"
  if verbose: dbg state
  let nimDir = state.nimDir
  state.binDir = nimDir/"bin"

  if nimDir.dirExists:
    doAssert fileExists(nimDir / "lib/system.nim"), fmt"nimDir is not a nim repo: {nimDir}"
  else:
    createDir nimDir.parentDir
    gitClone("https://github.com/nim-lang/Nim", nimDir)
  state.csourceV0 = CsourcesState(dir: nimDir/"csources", url: "https://github.com/nim-lang/csources.git", name: "csources", revs: csourcesRevs)
  state.csourceV1 = CsourcesState(dir: nimDir/"csources_v1", url: "https://github.com/nim-lang/csources_v1.git", name: "csources_v1", revs: csourcesV1Revs)
  for copt in [state.csourceV0, state.csourceV1]:
    copt.binDir = state.binDir
    copt.fetch = opt.fetch
    if opt.buildAllCsources:
      buildCsourcesAnyRevs(copt)

  if opt.fetch: gitFetch(nimDir)
  if state.rev.len > 0:
    gitResetHard(nimDir, state.rev)
  state.rev = gitCurrentRev(state.nimDir)
  let nimDiggerExe = state.binDir / fmt"nim_nimdigger_nim_{state.rev}{ExeExt2}"
  if opt.compileNim:
    let isCached = nimDiggerExe.fileExists
    echo fmt"digger getting nim: {nimDiggerExe} cached: {isCached}"
    if not isCached:
      let copt = getCsourcesState(state)
      buildCsourcesRev(copt)
      discard runCmdOutput(fmt"{copt.nimCsourcesExe} c -o:{nimDiggerExe} -d:release --hints:off --skipUserCfg compiler/nim.nim", nimDir)
    copyFile(nimDiggerExe, state.binDir / "nim" & ExeExt2)

  if opt.oldnew.len > 0:
    let oldnew2 = opt.oldnew.split("..")
    doAssert oldnew2.len == 2, opt.oldnew
    let oldrev = oldnew2[0]
    let newrev = oldnew2[1]
    doAssert oldrev.len > 0 # for regressions, aka goodrev
    doAssert newrev.len > 0 # for a regressions, aka badrev 
    gitCleanDanger(state.nimDir, requireConfirmation = true)
    proc bisectStart(old, new: string)=
      runCmd(fmt"git -C {state.nimDir.quoteShell} bisect start --term-old {old} --term-new {new} {newrev} {oldrev}")
    if opt.bisectBugfix: bisectStart("BROKEN", "BUGFIX")
    else: bisectStart("WORKS", "REGRESSION")
    let exe = getAppFileName()
    var msg = opt.bisectCmd
    if opt.bisectBugfix:
      msg = fmt"! ({msg})" # negate exit code
    let bisectCmd2 = fmt"{exe} --compileNim && ( {msg} )"
    runCmd(fmt"git -C {state.nimDir.quoteShell} bisect run bash -c {bisectCmd2.quoteShell}")

proc main(rev = "", nimDir = "", compileNim = false, fetch = false, oldnew = "", bisectBugfix = false, verbose = false, bisectCmd = "", args: seq[string]) =
  nimdigger.verbose = verbose
  var bisectCmd = bisectCmd
  if bisectCmd.len == 0:
    bisectCmd = args.quoteShellCommand
  else:
    doAssert args.len == 0
  main2(DiggerOpt.construct(rev, nimDir, compileNim, fetch, bisectCmd, oldnew, bisectBugfix))

when isMainModule:
  import pkg/cligen
  dispatch main
