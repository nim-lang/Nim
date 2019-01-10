#[
nimble wide CI
]#

import std/[os, strutils, json, tables, macros, times]
import compiler/asciitables

proc getNimblePkgPath(nimbleDir: string): string =
  nimbleDir / "packages_official.json"

template withDir*(dir, body) =
  let old = getCurrentDir()
  try:
    setCurrentDir(dir)
    body
  finally:
    setCurrentdir(old)

proc execEcho(cmd: string): bool =
  echo "running cmd:", cmd
  let status = execShellCmd(cmd)
  if status != 0:
    echo "failed: cmd: `", cmd, "` status:", status
  result = status == 0

type Stats = object
  seenOK: int
  foundOK: int                ## whether nimble can still access it
  cloneOK: int
  installOK: int
  developOK: int
  buildOK: int
  testOK: int
  totalTime: float

type TestResult = ref object
  # we can add further test fields here (eg running time, mem usage etc)
  pkg: string
  stats: Stats

type TestResultAll = object
  tests: seq[TestResult]
  stats: Stats
  failures: seq[string]

proc parseNimble(data: JsonNode): Table[string, JsonNode] =
  result = initTable[string, JsonNode]()
  for a in data:
    result[a["name"].getStr()] = a

type Config = ref object
  pkgs: Table[string, JsonNode]
  pkgInstall: string
  pkgClone: string

proc runCIPackage(config: Config, data: var TestResult) =
  let t0 = epochTime()
  defer:
    data.stats.totalTime = epochTime() - t0
  let pkg = data.pkg
  echo "runCIPackage:", pkg
  data.stats.seenOK.inc
  if not(pkg in config.pkgs):
    echo "not found: ", pkg
    return
  data.stats.foundOK.inc
  let url = config.pkgs[pkg]["url"].getStr()

  when true:
    let cmd = "nimble install --nimbleDir:$# -y $# " % [config.pkgInstall,
        pkg]
    if execEcho(cmd):
      data.stats.installOK.inc

  echo config.pkgClone
  createDir config.pkgClone
  withDir config.pkgClone:
    if not existsDir pkg:
      if execEcho("nimble develop --nimbleDir:$# -y $#" % [config.pkgInstall,
          pkg]):
        data.stats.developOK.inc
      if not execEcho("git clone $# $#" % [url, pkg]):
        return                # nothing left to do without a clone
    data.stats.cloneOK.inc

  withDir config.pkgClone / pkg:
    data.stats.buildOK = ord execEcho("nimble build -N --nimbleDir:$#" % [
        config.pkgInstall])
    # note: see caveat https://github.com/nim-lang/nimble/issues/558
    # where `nimble test` suceeds even if no tests are defined.
    data.stats.testOK = ord execEcho "nimble test"

proc tabFormat[T](result: var string, a: T) =
  # TODO: more generic, flattens anything into 1 line of a table
  var first = true
  for k, v in fieldPairs(a):
    if first: first = false
    else: result.add "\t"
    result.add k
    result.add ":\t"
    result.add v

proc `$`(a: TestResultAll): string =
  var s = ""
  for i, ai in a.tests:
    s.tabFormat (i: i, pkg: ai.pkg)
    s.add "\t"
    s.tabFormat ai.stats
    s.add "\n"
  when true: # add total
    s.add("TOTAL\t$#\t\t\t" % [$a.tests.len])
    s.tabFormat a.stats
    s.add "\n"
  result = "TestResultAll:\n" & alignTable(s)

proc updateResults(a: var TestResultAll, b: TestResult) =
  a.tests.add b
  if b.stats.testOK == 0:
    a.failures.add b.pkg
  macro domixin(s: static[string]): untyped = parseStmt(s)
  for k, v in fieldPairs(b.stats):
    domixin("a.stats.$# += b.stats.$#" % [k, k])

proc runCIPackages*(dirOutput: string) =
  echo "runCIPackages", (dirOutput: dirOutput, pid: getCurrentProcessId())
    # pid useful to kill process, since because of a bug, ^C doesn't work inside exec

  var data: TestResult
  let pkgs0 = """
# add more packages here; lines starting with `#` are skipped

#TODO: jester@#head or jester? etc
jester

cligen

# CT failures
libffi

glob
nimongo
nimx
karax
freeimage
regex
nimpy
zero_functional
arraymancer
inim
c2nim
sdl1
iterutils
gnuplot
nimpb
lazy
choosenim
"""

  var config = Config(
    pkgInstall: dirOutput/"nimbleRoot",
    pkgClone: dirOutput/"nimbleCloneRoot",
  )

  doAssert execEcho "nimble refresh --nimbleDir:$#" % [config.pkgInstall]
  # doing it by hand until nimble exposes this API
  config.pkgs = config.pkgInstall.getNimblePkgPath.readFile.parseJson.parseNimble()

  var pkgs: seq[string]
  for a in pkgs0.splitLines:
    var a = a.strip
    if a.len == 0: continue
    if a.startsWith '#': continue
    pkgs.add a

  echo (pkgs: pkgs)

  var testsAll: TestResultAll

  for i, pkg in pkgs:
    var data = TestResult(pkg: pkg)
    runCIPackage(config, data)
    updateResults(testsAll, data)
    if data.stats.testOK == 0: echo "FAILURE:CI pkg:" & pkg
    echo testsAll
  # consider sending a notification, gather stats on failed packages

when isMainModule:
  runCIPackages(".")
