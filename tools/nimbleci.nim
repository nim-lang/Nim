#[
nimble wide CI
]#

import os, strutils

template withDir*(dir, body) =
  let old = getCurrentDir()
  try:
    setCurrentDir(dir)
    body
  finally:
    setCurrentdir(old)

proc execEcho(cmd: string): bool =
  echo "running:", cmd
  let status = execShellCmd(cmd)
  if status != 0:
    echo "failed: cmd: ", cmd, " status:", status
  result = status == 0

type TestResult = ref object
  # we can add further test fields here (eg running time, mem usage etc)
  pkg: string
  installOK: bool
  developOK: bool
  buildOK: bool
  testOK: bool

proc runCIPackage(data: var TestResult) =
  let pkg = data.pkg
  echo "runCIPackage:", pkg
  let pkgInstall = "nimbleRoot"
  let pkgClone = "nimbleRoot"

  let cmd = "nimble install --nimbleDir:$# -y $# " % [pkgInstall, pkg]
  if not execEcho(cmd):
    echo "FAILURE: runCIPackage:", pkg
    return
  data.installOK = true

  withDir pkgClone:
    if not execEcho("nimble develop -y $#" % [pkg]):
      return
    data.developOK = true

  withDir pkgClone / pkg:
    data.buildOK = execEcho "nimble build"
    # note: see caveat https://github.com/nim-lang/nimble/issues/558
    # where `nimble test` suceeds even if no tests are defined.
    data.testOK = execEcho "nimble test"

proc runCIPackages*() =
  echo "runCIPackages"

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

  var pkgs: seq[string]
  for a in pkgs0.splitLines:
    var a = a.strip
    if a.len == 0: continue
    if a.startsWith '#': continue
    pkgs.add a

  echo (pkgs: pkgs)

  var tests: seq[TestResult]
  type Stats = object
    num: int
    installOK: int
    developOK: int
    buildOK: int
    testOK: int

  var stats: Stats
  proc toStr(a: Stats): string =
    result = $a # consider human formatting if needed

  for i,pkg in pkgs:
    var data = TestResult(pkg:pkg)
    runCIPackage(data)
    tests.add data
    stats.num.inc
    stats.installOK+=data.installOK.ord
    if not data.testOK: echo "FAILURE:CI"
    echo (count:i, n: pkgs.len, stats:stats.toStr, pkg: pkg, testOK: data.testOK)
  
  var failures: seq[string]
  for a in tests:
    if not a.testOK:
      failures.add a.pkg
  echo (finalStats:stats.toStr, failures:failures)
  # consider sending a notification, gather stats on failed packages

when isMainModule:
  runCIPackages()
