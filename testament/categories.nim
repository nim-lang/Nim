#
#
#            Nim Tester
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Include for the tester that contains test suites that test special features
## of the compiler.

# included from testament.nim

import important_packages
import std/[strformat, strutils, tables]
from std/sequtils import filterIt

const
  specialCategories = [
    "assert",
    "async",
    "debugger",
    "dll",
    "examples",
    "gc",
    "io",
    "js",
    "ic",
    "ic_disabled",
    "lib",
    "manyloc",
    "nimble-packages",
    "niminaction",
    "threads",
    "untestable", # see trunner_special
    "testdata",
    "nimcache",
    "coroutines",
    "osproc",
    "shouldfail",
    "destructor"
  ]

proc isTestFile*(file: string): bool =
  let (_, name, ext) = splitFile(file)
  result = ext == ".nim" and name.startsWith("t")

# --------------------- DLL generation tests ----------------------------------

proc runBasicDLLTest(c, r: var TResults, cat: Category, options: string, isOrc = false) =
  const rpath = when defined(macosx):
      " --passL:-rpath --passL:@loader_path"
    else:
      ""

  var test1 = makeTest("lib/nimrtl.nim", options & " --outdir:tests/dll", cat)
  test1.spec.action = actionCompile
  testSpec c, test1
  var test2 = makeTest("tests/dll/server.nim", options & " --threads:on" & rpath, cat)
  test2.spec.action = actionCompile
  testSpec c, test2

  var test3 = makeTest("lib/nimhcr.nim", options & " --threads:off --outdir:tests/dll" & rpath, cat)
  test3.spec.action = actionCompile
  testSpec c, test3
  var test4 = makeTest("tests/dll/visibility.nim", options & " --threads:off --app:lib" & rpath, cat)
  test4.spec.action = actionCompile
  testSpec c, test4

  # windows looks in the dir of the exe (yay!):
  when not defined(windows):
    # posix relies on crappy LD_LIBRARY_PATH (ugh!):
    const libpathenv = when defined(haiku): "LIBRARY_PATH"
                       else: "LD_LIBRARY_PATH"
    var libpath = getEnv(libpathenv)
    # Temporarily add the lib directory to LD_LIBRARY_PATH:
    putEnv(libpathenv, "tests/dll" & (if libpath.len > 0: ":" & libpath else: ""))
    defer: putEnv(libpathenv, libpath)

  testSpec r, makeTest("tests/dll/client.nim", options & " --threads:on" & rpath, cat)
  testSpec r, makeTest("tests/dll/nimhcr_unit.nim", options & " --threads:off" & rpath, cat)
  testSpec r, makeTest("tests/dll/visibility.nim", options & " --threads:off" & rpath, cat)

  if "boehm" notin options:
    # hcr tests

    var basicHcrTest = makeTest("tests/dll/nimhcr_basic.nim", options & " --threads:off --forceBuild --hotCodeReloading:on " & rpath, cat)
    # test segfaults for now but compiles:
    if isOrc: basicHcrTest.spec.action = actionCompile
    testSpec r, basicHcrTest

    # force build required - see the comments in the .nim file for more details
    var hcri = makeTest("tests/dll/nimhcr_integration.nim",
                                   options & " --threads:off --forceBuild --hotCodeReloading:on" & rpath, cat)
    let nimcache = nimcacheDir(hcri.name, hcri.options, getTestSpecTarget())
    let cmd = prepareTestCmd(hcri.spec.getCmd, hcri.name,
                                hcri.options, nimcache, getTestSpecTarget())
    hcri.testArgs = cmd.parseCmdLine
    testSpec r, hcri

proc dllTests(r: var TResults, cat: Category, options: string) =
  # dummy compile result:
  var c = initResults()

  runBasicDLLTest c, r, cat, options & " --mm:refc"
  runBasicDLLTest c, r, cat, options & " -d:release --mm:refc"
  runBasicDLLTest c, r, cat, options, isOrc = true
  runBasicDLLTest c, r, cat, options & " -d:release", isOrc = true
  when not defined(windows) and not defined(osx):
    # boehm library linking broken on macos 13
    # still cannot find a recent Windows version of boehm.dll:
    runBasicDLLTest c, r, cat, options & " --gc:boehm"
    runBasicDLLTest c, r, cat, options & " -d:release --gc:boehm"

# ------------------------------ GC tests -------------------------------------

proc gcTests(r: var TResults, cat: Category, options: string) =
  template run(filename, extraOptions: untyped) =
    testSpec r, makeTest("tests/gc" / filename, options & extraOptions, cat)

  # The matrix every gc test file goes through: refc (debug + realtime-release)
  # and orc (debug + release). This is the coverage we actually rely on today.
  template test(filename: untyped) =
    run filename, " --mm:refc"
    run filename, " -d:release -d:useRealtimeGC --mm:refc"
    run filename, " --gc:orc"
    run filename, " --gc:orc -d:release"

  # markAndSweep and boehm are legacy collectors. Exercising them for every gc
  # test file tripled this category's CI cost for little added signal, so only
  # `gctest` keeps them alive. `gctest` does not build under orc.
  template testLegacyGc(filename: untyped) =
    run filename, " --mm:refc"
    run filename, " -d:release -d:useRealtimeGC --mm:refc"
    run filename, " --gc:markAndSweep"
    run filename, " -d:release --gc:markAndSweep"
    when not defined(windows) and not defined(android) and not defined(osx):
      # boehm linking is broken on macOS 13 and there is no usable boehm.dll for
      # Windows, so those platforms skip it.
      run filename, " --gc:boehm"
      run filename, " -d:release --gc:boehm"

  testLegacyGc "gctest"

  test "foreign_thr"
  test "gcemscripten"
  test "growobjcrash"
  test "gcbench"
  test "gcleak"
  test "gcleak2"
  test "gcleak3"
  test "gcleak4"
  # Disabled because it works and takes too long to run:
  #test "gcleak5"
  test "weakrefs"
  test "cycleleak"
  test "closureleak"
  test "refarrayleak"
  test "tlists"
  test "thavlak"
  test "stackrefleak"
  test "cyclecollector"
  test "trace_globals"
  test "tfinalizers"

# ------------------------- threading tests -----------------------------------

proc threadTests(r: var TResults, cat: Category, options: string) =
  template test(filename: untyped) =
    testSpec r, makeTest(filename, options, cat)
    testSpec r, makeTest(filename, options & " -d:release", cat)
    testSpec r, makeTest(filename, options & " --tlsEmulation:on", cat)
  for t in os.walkFiles("tests/threads/t*.nim"):
    test(t)

# ------------------------- IO tests ------------------------------------------

proc ioTests(r: var TResults, cat: Category, options: string) =
  # We need readall_echo to be compiled for this test to run.
  # dummy compile result:
  var c = initResults()
  testSpec c, makeTest("tests/system/helpers/readall_echo", options, cat)
  #        ^- why is this not appended to r? Should this be discarded?
  # EDIT: this should be replaced by something like in D20210524T180826,
  # likewise in similar instances where `testSpec c` is used, or more generally
  # when a test depends on another test, as it makes tests non-independent,
  # creating complications for batching and megatest logic.
  testSpec r, makeTest("tests/system/tio", options, cat)

# ------------------------- async tests ---------------------------------------
proc asyncTests(r: var TResults, cat: Category, options: string) =
  # Run async with yrc instead of the default orc; the CI already runs long
  # enough that we cannot afford to test both.
  template test(filename: untyped) =
    testSpec r, makeTest(filename, options & " --mm:yrc", cat)
  for t in os.walkFiles("tests/async/t*.nim"):
    test(t)

# ------------------------- debugger tests ------------------------------------

proc debuggerTests(r: var TResults, cat: Category, options: string) =
  if fileExists("tools/nimgrep.nim"):
    var t = makeTest("tools/nimgrep", options & " --debugger:on", cat)
    t.spec.action = actionCompile
    # force target to C because of MacOS 10.15 SDK headers bug
    # https://github.com/nim-lang/Nim/pull/15612#issuecomment-712471879
    t.spec.targets = {targetC}
    testSpec r, t

# ------------------------- JS tests ------------------------------------------

proc jsTests(r: var TResults, cat: Category, options: string) =
  template test(filename: untyped) =
    testSpec r, makeTest(filename, options, cat), {targetJS}
    testSpec r, makeTest(filename, options & " -d:release", cat), {targetJS}

  for t in os.walkFiles("tests/js/t*.nim"):
    test(t)
  for testfile in ["exception/texceptions", "exception/texcpt1",
                   "exception/texcsub", "exception/tfinally",
                   "exception/tfinally2", "exception/tfinally3",
                   "collections/tactiontable", "method/tmultimjs",
                   "varres/tvarres0", "varres/tvarres3", "varres/tvarres4",
                   "varres/tvartup", "int/tints", "int/tunsignedinc",
                   "async/tjsandnativeasync"]:
    test "tests/" & testfile & ".nim"

  for testfile in ["strutils", "json", "random", "times", "logging"]:
    test "lib/pure/" & testfile & ".nim"

# ------------------------- nim in action -----------

proc testNimInAction(r: var TResults, cat: Category, options: string) =
  template test(filename: untyped) =
    testSpec r, makeTest(filename, options, cat)

  template testJS(filename: untyped) =
    testSpec r, makeTest(filename, options, cat), {targetJS}

  template testCPP(filename: untyped) =
    testSpec r, makeTest(filename, options, cat), {targetCpp}

  let tests = [
    "niminaction/Chapter1/various1",
    "niminaction/Chapter2/various2",
    "niminaction/Chapter2/resultaccept",
    "niminaction/Chapter2/resultreject",
    "niminaction/Chapter2/explicit_discard",
    "niminaction/Chapter2/no_def_eq",
    "niminaction/Chapter2/no_iterator",
    "niminaction/Chapter2/no_seq_type",
    "niminaction/Chapter3/ChatApp/src/server",
    "niminaction/Chapter3/ChatApp/src/client",
    "niminaction/Chapter3/various3",
    "niminaction/Chapter6/WikipediaStats/concurrency_regex",
    "niminaction/Chapter6/WikipediaStats/concurrency",
    "niminaction/Chapter6/WikipediaStats/naive",
    "niminaction/Chapter6/WikipediaStats/parallel_counts",
    "niminaction/Chapter6/WikipediaStats/race_condition",
    "niminaction/Chapter6/WikipediaStats/sequential_counts",
    "niminaction/Chapter6/WikipediaStats/unguarded_access",
    "niminaction/Chapter7/Tweeter/src/tweeter",
    "niminaction/Chapter7/Tweeter/src/createDatabase",
    "niminaction/Chapter7/Tweeter/tests/database_test",
    "niminaction/Chapter8/sdl/sdl_test"
    ]

  when false:
    # Verify that the files have not been modified. Death shall fall upon
    # whoever edits these hashes without dom96's permission, j/k. But please only
    # edit when making a conscious breaking change, also please try to make your
    # commit message clear and notify me so I can easily compile an errata later.
    # ---------------------------------------------------------
    # Hash-checks are disabled for Nim 1.1 and beyond
    # since we needed to fix the deprecated unary '<' operator.
    const refHashes = @[
      "51afdfa84b3ca3d810809d6c4e5037ba",
      "30f07e4cd5eaec981f67868d4e91cfcf",
      "d14e7c032de36d219c9548066a97e846",
      "b335635562ff26ec0301bdd86356ac0c",
      "6c4add749fbf50860e2f523f548e6b0e",
      "76de5833a7cc46f96b006ce51179aeb1",
      "705eff79844e219b47366bd431658961",
      "a1e87b881c5eb161553d119be8b52f64",
      "2d706a6ec68d2973ec7e733e6d5dce50",
      "c11a013db35e798f44077bc0763cc86d",
      "3e32e2c5e9a24bd13375e1cd0467079c",
      "a5452722b2841f0c1db030cf17708955",
      "dc6c45eb59f8814aaaf7aabdb8962294",
      "69d208d281a2e7bffd3eaf4bab2309b1",
      "ec05666cfb60211bedc5e81d4c1caf3d",
      "da520038c153f4054cb8cc5faa617714",
      "59906c8cd819cae67476baa90a36b8c1",
      "9a8fe78c588d08018843b64b57409a02",
      "8b5d28e985c0542163927d253a3e4fc9",
      "783299b98179cc725f9c46b5e3b5381f",
      "1a2b3fba1187c68d6a9bfa66854f3318",
      "391ff57b38d9ea6f3eeb3fe69ab539d3"
    ]
    for i, test in tests:
      let filename = testsDir / test.addFileExt("nim")
      let testHash = getMD5(readFile(filename).string)
      doAssert testHash == refHashes[i], "Nim in Action test " & filename &
          " was changed: " & $(i: i, testHash: testHash, refHash: refHashes[i])

  # Run the tests.
  for testfile in tests:
    test "tests/" & testfile & ".nim"
  let jsFile = "tests/niminaction/Chapter8/canvas/canvas_test.nim"
  testJS jsFile
  let cppFile = "tests/niminaction/Chapter8/sfml/sfml_test.nim"
  testCPP cppFile

# ------------------------- manyloc -------------------------------------------

proc findMainFile(dir: string): string =
  # finds the file belonging to ".nim.cfg"; if there is no such file
  # it returns the some ".nim" file if there is only one:
  const cfgExt = ".nim.cfg"
  result = ""
  var nimFiles = 0
  for kind, file in os.walkDir(dir):
    if kind == pcFile:
      if file.endsWith(cfgExt): return file[0..^(cfgExt.len+1)] & ".nim"
      elif file.endsWith(".nim"):
        if result.len == 0: result = file
        inc nimFiles
  if nimFiles != 1: result.setLen(0)

proc manyLoc(r: var TResults, cat: Category, options: string) =
  for kind, dir in os.walkDir("tests/manyloc"):
    if kind == pcDir:
      when defined(windows):
        if dir.endsWith"nake": continue
      if dir.endsWith"named_argument_bug": continue
      let mainfile = findMainFile(dir)
      if mainfile != "":
        var test = makeTest(mainfile, options, cat)
        test.spec.action = actionCompile
        testSpec r, test

proc compileExample(r: var TResults, pattern, options: string, cat: Category) =
  for test in os.walkFiles(pattern):
    var test = makeTest(test, options, cat)
    test.spec.action = actionCompile
    testSpec r, test

proc testStdlib(r: var TResults, pattern, options: string, cat: Category) =
  var files: seq[string] = @[]

  proc isValid(file: string): bool =
    for dir in parentDirs(file, inclusive = false):
      if dir.lastPathPart in ["includes", "nimcache"]:
        # e.g.: lib/pure/includes/osenv.nim gives: Error: This is an include file for os.nim!
        return false
    let name = extractFilename(file)
    if name.splitFile.ext != ".nim": return false
    for namei in disabledFiles:
      # because of `LockFreeHash.nim` which has case
      if namei.cmpPaths(name) == 0: return false
    return true

  for testFile in os.walkDirRec(pattern):
    if isValid(testFile):
      files.add testFile

  files.sort # reproducible order
  for testFile in files:
    let contents = readFile(testFile)
    var testObj = makeTest(testFile, options, cat)
    #[
    todo:
    this logic is fragile:
    false positives (if appears in a comment), or false negatives, e.g.
    `when defined(osx) and isMainModule`.
    Instead of fixing this, see https://github.com/nim-lang/Nim/issues/10045
    for a much better way.
    ]#
    if "when isMainModule" notin contents:
      testObj.spec.action = actionCompile
    testSpec r, testObj

# ----------------------------- nimble ----------------------------------------
proc listPackagesAll(): seq[NimblePackage] =
  result = @[]
  var nimbleDir = getEnv("NIMBLE_DIR")
  if nimbleDir.len == 0: nimbleDir = getHomeDir() / ".nimble"
  let packageIndex = nimbleDir / "packages_official.json"
  let packageList = parseFile(packageIndex)
  proc findPackage(name: string): JsonNode =
    result = nil
    for a in packageList:
      if a["name"].str == name: return a
  for pkg in important_packages.packages.items:
    var pkg = pkg
    if pkg.url.len == 0:
      let pkg2 = findPackage(pkg.name)
      if pkg2 == nil:
        raise newException(ValueError, "Cannot find package '$#'." % pkg.name)
      pkg.url = pkg2["url"].str
    result.add pkg

proc listPackages(packageFilter: string): seq[NimblePackage] =
  let pkgs = listPackagesAll()
  if packageFilter.len != 0:
    # xxx document `packageFilter`, seems like a bad API,
    # at least should be a regex; a substring match makes no sense.
    result = pkgs.filterIt(packageFilter in it.name)
  else:
    if testamentData0.testamentNumBatch == 0:
      result = pkgs
    else:
      result = @[]
      for i in 0..<pkgs.len:
        if i mod testamentData0.testamentNumBatch == testamentData0.testamentBatch:
          result.add pkgs[i]

proc makeSupTest(test, options: string, cat: Category, debugInfo = ""): TTest =
  result = TTest(cat: cat, name: test, options: options, debugInfo: debugInfo,
                startTime: epochTime())

import std/private/gitutils

proc testNimblePackages(r: var TResults; cat: Category; packageFilter: string) =
  let nimbleExe = findExe("nimble")
  doAssert nimbleExe != "", "Cannot run nimble tests: Nimble binary not found."
  doAssert execCmd("$# update" % nimbleExe) == 0, "Cannot run nimble tests: Nimble update failed."
  let packageFileTest = makeSupTest("PackageFileParsed", "", cat)
  let packagesDir = "pkgstemp"
  createDir(packagesDir)
  var errors = 0
  try:
    let pkgs = listPackages(packageFilter)
    for i, pkg in pkgs:
      inc r.total
      var test = makeSupTest(pkg.name, "", cat, "[$#/$#] " % [$i, $pkgs.len])
      let buildPath = packagesDir / pkg.name
      template tryCommand(cmd: string, workingDir2 = buildPath, reFailed = reInstallFailed, maxRetries = 1): string =
        var outp: string = ""
        let ok = retryCall(maxRetry = maxRetries, backoffDuration = 10.0):
          var status: int
          (outp, status) = execCmdEx(cmd, workingDir = workingDir2)
          status == QuitSuccess
        if not ok:
          r.finishTest(test, targetC, "", "", cmd & "\n" & outp, reFailed)
          continue
        outp

      if not dirExists(buildPath):
        discard tryCommand("git clone $# $#" % [pkg.url.quoteShell, buildPath.quoteShell], workingDir2 = ".", maxRetries = 3)
        if not pkg.useHead:
          discard tryCommand("git fetch --tags", maxRetries = 3)
          let describeOutput = tryCommand("git describe --tags --abbrev=0")
          discard tryCommand("git checkout $#" % [describeOutput.strip.quoteShell])
        discard tryCommand("nimble install --depsOnly -y", maxRetries = 3)
      let cmds = pkg.cmd.split(';')
      for i in 0 ..< cmds.len - 1:
        discard tryCommand(cmds[i], maxRetries = 3)
      discard tryCommand(cmds[^1], reFailed = reBuildFailed)
      inc r.passed
      r.finishTest(test, targetC, "", "", "", reSuccess)

    errors = r.total - r.passed
    if errors == 0:
      r.finishTest(packageFileTest, targetC, "", "", "", reSuccess)
    else:
      r.finishTest(packageFileTest, targetC, "", "", "", reBuildFailed)

  except JsonParsingError:
    errors = 1
    r.finishTest(packageFileTest, targetC, "", "", "Invalid package file", reBuildFailed)
    raise
  except ValueError:
    errors = 1
    r.finishTest(packageFileTest, targetC, "", "", "Unknown package", reBuildFailed)
    raise # bug #18805
  finally:
    if errors == 0: removeDir(packagesDir)

# ---------------- IC tests ---------------------------------------------

# ---- Metamorphic IC tests --------------------------------------------------
#
# A metamorphic IC test drives a *sequence of edits across several modules*
# through `nim ic` in a fixed build directory (same absolute paths throughout,
# which is what keeps the cache content-stable) and asserts the invariants the
# incremental backend is supposed to guarantee — see doc/ic_ideas.md:
#
#   * clean build == incremental build      (a fresh in-place rebuild of the
#                                            final sources is byte-identical to
#                                            the binary and full cache set the
#                                            incremental edits converged to)
#   * a no-op edit changes no artifact       (`noop`)
#   * a body-only edit touches no interface  (`body-edit`: no `*.iface.bif`
#                                            cookie changes -> no importer re-sem)
#   * an interface edit propagates to        (`iface-edit`: an `*.iface.bif`
#     importers                              cookie changes and >= 2 modules'
#                                            `*.s.bif` codegen is rebuilt)
#
# File format (a `tests/ic/t*.nim` whose body, after the spec header, contains a
# line `#? metamorphic`):
#
#   #? metamorphic
#   #!FILE a.nim
#   proc greet*(): string = "hi"
#   #!FILE main.nim          # `main.nim` is always the build root
#   import a
#   echo greet()
#   #!STEP expect: hi
#   #!FILE a.nim             # re-emit a module to "edit" it
#   proc greet*(): string = "hi"   # identical content
#   #!STEP expect: hi; noop
#
# `#!FILE <name>` blocks (re)write a module in the virtual file system; the
# accumulated file set is materialised before each `#!STEP`. A `#!STEP`'s
# attributes are `;`-separated, each either `key: value` or a bare flag:
#   expect: <stdout>   noop   body-edit   iface-edit   modules: <n>   clean
# The last step always also runs the clean==incremental check.

type MetamorphicError = object of CatchableError
  resultKind: TResultEnum
  expected, given: string

proc mmRaise(kind: TResultEnum, expected, given: string) =
  var e = newException(MetamorphicError, given)
  e.resultKind = kind
  e.expected = expected
  e.given = given
  raise e

proc isMetamorphicIcTest(content: string): bool =
  result = false
  for line in content.splitLines:
    if line.strip == "#? metamorphic": return true

proc snapshotDir(dir: string): Table[string, string] =
  ## relative path -> raw file contents, for every file under `dir`.
  result = initTable[string, string]()
  if dirExists(dir):
    for it in walkDirRec(dir):
      result[it.relativePath(dir)] = readFile(it)

proc changedPaths(prev, cur: Table[string, string]): seq[string] =
  result = @[]
  for k, v in cur:
    if prev.getOrDefault(k) != v: result.add k
  for k in prev.keys:
    if k notin cur: result.add k

proc isProvenance(path: string): bool =
  ## Build-provenance sidecars that legitimately differ between a fresh build and
  ## an edit-accumulated one (they record build history, not codegen). Excluded
  ## only from the cross-build clean==incremental comparison — a *no-op* edit must
  ## still leave even these untouched.
  path.endsWith(".frontend.build.nif")

proc stableBinary(path: string): string =
  ## Contents of a linked executable past its header region, for comparing whether
  ## two builds produced the same *code*. Linkers embed build-time-volatile fields
  ## in the header (e.g. the mingw PE `TimeDateStamp` and its derived `CheckSum`),
  ## so two builds seconds apart differ there even with identical codegen. Skipping
  ## a generous fixed window keeps the clean-vs-incremental check about codegen.
  const headerSkip = 4096
  var f: File = nil
  if not open(f, path, fmRead):
    raise newException(IOError, "cannot open: " & path)
  defer: close(f)
  if getFileSize(f) > headerSkip:
    setFilePos(f, headerSkip)
  result = readAll(f)

proc changedModuleCount(changed: seq[string]): int =
  ## distinct modules whose codegen (`*.s.bif`) was rebuilt.
  var mods: seq[string] = @[]
  for p in changed:
    if p.endsWith(".s.bif"):
      let key = p.extractFilename.split('.')[0]
      if key notin mods: mods.add key
  result = mods.len

proc xxdRange(s: string; start, count: int): string =
  ## 16-byte hex+ASCII lines. Kept to short lines so Azure does not clip them.
  result = ""
  if s.len == 0:
    return "  (empty)\n"
  var i = max(0, start)
  let last = min(s.len, i + max(count, 0))
  if i >= last:
    return "  (no bytes in window)\n"
  while i < last:
    result.add "  "
    result.add toHex(i, 8)
    result.add ": "
    let lineEnd = min(i + 16, last)
    var ascii = newStringOfCap(16)
    var j = i
    while j < lineEnd:
      result.add toHex(uint8(ord(s[j])), 2)
      result.add ' '
      let c = s[j]
      ascii.add(if c >= ' ' and c <= '~': c else: '.')
      inc j
    var pad = lineEnd
    while pad < i + 16:
      result.add "   "
      inc pad
    result.add ' '
    result.add ascii
    result.add '\n'
    i = lineEnd

proc printableSpans(s: string; minLen = 8): seq[string] =
  ## ASCII runs from a `.bif` (string/symbol pools, cookie hashes).
  result = @[]
  var cur = ""
  for c in s:
    if c >= ' ' and c <= '~':
      cur.add c
    else:
      if cur.len >= minLen: result.add cur
      cur.setLen 0
  if cur.len >= minLen: result.add cur

proc firstDiffAt(a, b: string): int =
  let n = min(a.len, b.len)
  result = 0
  while result < n and a[result] == b[result]: inc result

proc countDiffBytes(a, b: string): int =
  let n = min(a.len, b.len)
  result = abs(a.len - b.len)
  for i in 0 ..< n:
    if a[i] != b[i]: inc result

proc cacheDiffReport(paths: seq[string]; left, right: Table[string, string];
                     leftName, rightName: string): string =
  ## Comparison of differing cache files only. Cookies are dumped entirely;
  ## larger `.s.bif`/`.t.bif` files get a hex window around the first difference
  ## plus a unified diff of printable spans (pool strings / hashes).
  var sorted = paths
  sorted.sort()
  result = leftName & " files: " & $left.len & "\n"
  result.add rightName & " files: " & $right.len & "\n"
  result.add "differing paths (" & $sorted.len & "):\n"
  for p in sorted:
    result.add "==== "
    result.add p
    result.add " ====\n"
    let inL = p in left
    let inR = p in right
    if not inL:
      result.add "  only in " & rightName & " (" & $right[p].len & " B)\n"
      continue
    if not inR:
      result.add "  only in " & leftName & " (" & $left[p].len & " B)\n"
      continue
    let a = left[p]
    let b = right[p]
    result.add "  " & leftName & ": " & $a.len & " B  md5=" & getMD5(a) & "\n"
    result.add "  " & rightName & ": " & $b.len & " B  md5=" & getMD5(b) & "\n"
    let at = firstDiffAt(a, b)
    result.add "  first differ at byte " & $at &
      " (minLen=" & $min(a.len, b.len) & ")\n"
    result.add "  differing bytes (incl. size delta): " & $countDiffBytes(a, b) & "\n"
    const window = 128
    let hexStart = max(0, at - window div 2)
    result.add "  " & leftName & " xxd around first diff:\n"
    result.add xxdRange(a, hexStart, window)
    result.add "  " & rightName & " xxd around first diff:\n"
    result.add xxdRange(b, hexStart, window)
    if a.len <= 512:
      result.add "  " & leftName & " full xxd:\n"
      result.add xxdRange(a, 0, a.len)
    if b.len <= 512:
      result.add "  " & rightName & " full xxd:\n"
      result.add xxdRange(b, 0, b.len)
    let sa = printableSpans(a)
    let sb = printableSpans(b)
    if sa == sb:
      result.add "  printable spans IDENTICAL (" & $sa.len &
        " spans) — difference is binary layout/padding/ids\n"
    else:
      result.add "  printable span diff (" & leftName & " vs " & rightName & "):\n"
      try:
        result.add diffStrings(sa.join("\n") & "\n", sb.join("\n") & "\n").output
      except CatchableError as e:
        result.add "  (git diff failed: " & e.msg & "; span counts " &
          $sa.len & " vs " & $sb.len & ")\n"
      result.add '\n'

proc runMetamorphicIcTest(r: var TResults; file: string; cat: Category; options: string) =
  var test = TTest(cat: cat, name: file, options: options,
                   spec: initSpec(file), startTime: epochTime())
  test.spec.targets = {targetC}
  inc r.total

  # Absolute paths: `nim ic` runs with `workingDir = buildDir`, so a relative
  # `--nimcache` would resolve against the build dir, not where we read it back.
  let buildDir = (file.changeFileExt("") & "_mm").absolutePath
  let nc = buildDir / "nc"
  let bin = buildDir / "prog".addFileExt(ExeExt)
  removeDir(buildDir)
  createDir(buildDir)

  template compileIc(): untyped =
    execCmdEx2(compilerPrefix, ["ic", "--hint:Conf:off", "--warnings:off",
      "--nimcache:" & nc, "--out:" & bin, "main.nim"],
      workingDir = buildDir)

  # Parse the source into a flat op list: ("file", name, content) | ("step", attrs, "").
  type OpKind = enum opFile, opStep
  type Op = object
    kind: OpKind
    a, b: string
  var ops: seq[Op] = @[]
  block parse:
    var curName = ""
    var buf = ""
    template flushFile() =
      if curName.len > 0: ops.add Op(kind: opFile, a: curName, b: buf)
      curName = ""; buf = ""
    for raw in readFile(file).splitLines:
      let s = raw.strip
      if s.startsWith("#!FILE"):
        flushFile()
        curName = s["#!FILE".len .. ^1].strip
      elif s.startsWith("#!STEP"):
        flushFile()
        ops.add Op(kind: opStep, a: s["#!STEP".len .. ^1].strip)
      elif curName.len > 0:
        buf.add raw; buf.add "\n"
  let lastStep = block:
    var n = 0
    for o in ops:
      if o.kind == opStep: inc n
    n

  var vfs = initTable[string, string]()
  var prevSnap = initTable[string, string]()
  var prevBin = ""
  var stepIdx = 0
  try:
    for o in ops:
      if o.kind == opFile:
        vfs[o.a] = o.b
        continue
      inc stepIdx
      let where = "step " & $stepIdx
      # Parse step attributes.
      var attrs = initTable[string, string]()
      for part in o.a.split(';'):
        let p = part.strip
        if p.len == 0: continue
        let c = p.find(':')
        if c >= 0: attrs[p[0 ..< c].strip] = p[c+1 .. ^1].strip
        else: attrs[p] = ""

      for fn, content in vfs: writeFile(buildDir / fn, content)
      let (_, cout, ccode) = compileIc()
      if ccode != 0:
        mmRaise(reBuildFailed, "", where & ": `nim ic` failed:\n" & cout)
      let (_, rout, rcode) = execCmdEx2(bin.absolutePath, [], workingDir = buildDir)
      if rcode != 0:
        mmRaise(reBuildFailed, "", where & ": program exited with " & $rcode & ":\n" & rout)
      if "expect" in attrs:
        let want = attrs["expect"].replace("\\n", "\n")
        if rout.strip == want.strip: discard
        else: mmRaise(reOutputsDiffer, want, where & " output:\n" & rout.strip)

      let snap = snapshotDir(nc)
      let binBytes = stableBinary(bin)
      if stepIdx > 1:
        let changed = changedPaths(prevSnap, snap)
        if "noop" in attrs and (changed.len != 0 or binBytes != prevBin):
          let report = cacheDiffReport(changed, prevSnap, snap, "before", "after")
          echo report
          mmRaise(reOutputsDiffer, "no artifact change",
            where & ": no-op edit changed " & $changed.len & " cache file(s):\n" & report)
        if "body-edit" in attrs:
          for p in changed:
            if p.endsWith(".iface.bif"):
              mmRaise(reOutputsDiffer, "no interface change",
                where & ": body-only edit changed an interface cookie: " & p)
        if "iface-edit" in attrs:
          var sawIface = false
          for p in changed:
            if p.endsWith(".iface.bif"): sawIface = true
          if not sawIface:
            mmRaise(reOutputsDiffer, "interface change", where & ": interface edit changed no `*.iface.bif` cookie")
          if changedModuleCount(changed) < 2:
            mmRaise(reOutputsDiffer, "propagation to importer",
              where & ": interface edit did not propagate (only " & $changedModuleCount(changed) & " module rebuilt)")
        if "modules" in attrs:
          let want = parseInt(attrs["modules"])
          let got = changedModuleCount(changed)
          if got != want:
            mmRaise(reOutputsDiffer, $want & " modules rebuilt", where & ": " & $got & " module(s) rebuilt")
      prevSnap = snap
      prevBin = binBytes

      if "clean" in attrs or stepIdx == lastStep:
        removeDir(nc)
        let (_, cout2, ccode2) = compileIc()
        if ccode2 != 0:
          mmRaise(reBuildFailed, "", where & ": clean rebuild failed:\n" & cout2)
        let cleanSnap = snapshotDir(nc)
        let cleanBin = stableBinary(bin)
        if cleanBin != binBytes:
          mmRaise(reOutputsDiffer, "clean binary == incremental binary",
            where & ": clean rebuild produced a different binary")
        var diff: seq[string] = @[]
        for p in changedPaths(snap, cleanSnap):
          if not isProvenance(p): diff.add p
        if diff.len != 0:
          let report = cacheDiffReport(diff, snap, cleanSnap, "incremental", "clean")
          createDir("testresults")
          let dumpPath = "testresults" / extractFilename(file) & "_cache_diff.txt"
          writeFile(dumpPath, report)
          echo "wrote ", dumpPath
          echo report
          mmRaise(reOutputsDiffer, "clean cache == incremental cache",
            where & ": clean rebuild differs in " & $diff.len & " cache file(s):\n" & report)
        prevSnap = cleanSnap
        prevBin = cleanBin
    finishTest(r, test, targetC, "", "", "", reSuccess)
    inc r.passed
  except MetamorphicError:
    let e = (ref MetamorphicError)(getCurrentException())
    finishTest(r, test, targetC, "", e.expected, e.given, e.resultKind)

proc icTests(r: var TResults; testsDir: string, cat: Category, options: string;
             isNavigatorTest: bool) =
  template editedTest() =
    var test = makeTest(file, options, cat)
    test.spec.targets = {targetC}
    test.spec.cmd = compilerPrefix & " ic --hint:Conf:off --warnings:off $options " & file
    testSpecWithNimcache(r, test, nimcache)

  const tempExt = "_temp.nim"
  for it in walkDirRec(testsDir):
    # `_mm` directories hold materialised modules + nimcache for metamorphic
    # tests; never collect their files as tests in their own right.
    if "_mm" in it: continue
    if isTestFile(it) and not it.endsWith(tempExt):
      # TEMPORARY CI debug: only tests/ic/tmeta_async.nim
      if extractFilename(it) != "tmeta_async.nim":
        continue
      let content = readFile(it)
      if isMetamorphicIcTest(content):
        runMetamorphicIcTest(r, it, cat, options)
        continue

      let nimcache = nimcacheDir(it, options, targetC)
      removeDir(nimcache)

      for fragment in content.split("#!EDIT!#"):
        let file = it.replace(".nim", tempExt)
        writeFile(file, fragment)
        let oldPassed = r.passed
        editedTest()
        if r.passed != oldPassed+1: break

# ----------------------------------------------------------------------------

const AdditionalCategories = ["debugger", "examples", "lib", "ic", "navigator"]
const MegaTestCat = "megatest"

proc `&.?`(a, b: string): string =
  # candidate for the stdlib?
  result = if b.startsWith(a): b else: a & b

proc processSingleTest(r: var TResults, cat: Category, options, test: string, targets: set[TTarget], targetsSet: bool) =
  var targets = targets
  if not targetsSet:
    let target = if cat.string.normalize == "js": targetJS else: targetC
    targets = {target}
  doAssert fileExists(test), test & " test does not exist"
  testSpec r, makeTest(test, options, cat), targets

proc isJoinableSpec(spec: TSpec): bool =
  # xxx simplify implementation using a whitelist of fields that are allowed to be
  # set to non-default values (use `fieldPairs`), to avoid issues like bug #16576.
  result = useMegatest and not spec.sortoutput and
    spec.action == actionRun and
    not fileExists(spec.file.changeFileExt("cfg")) and
    not fileExists(spec.file.changeFileExt("nims")) and
    not fileExists(parentDir(spec.file) / "nim.cfg") and
    not fileExists(parentDir(spec.file) / "config.nims") and
    spec.cmd.len == 0 and
    spec.err != reDisabled and
    not spec.unjoinable and
    spec.exitCode == 0 and
    spec.retries == 0 and
    spec.input.len == 0 and
    spec.nimout.len == 0 and
    spec.nimoutFull == false and
      # so that tests can have `nimoutFull: true` with `nimout.len == 0` with
      # the meaning that they expect empty output.
    spec.matrix.len == 0 and
    spec.outputCheck != ocSubstr and
    spec.ccodeCheck.len == 0 and
    (spec.targets == {} or spec.targets == {targetC})
  if result:
    if spec.file.readFile.contains "when isMainModule":
      result = false

proc quoted(a: string): string =
  # TODO: consider moving to system.nim
  result = ""
  result.addQuoted(a)

proc runJoinedTest(r: var TResults, cat: Category, testsDir: string, options: string) =
  ## returns a list of tests that have problems
  #[
  xxx create a reusable megatest API after abstracting out testament specific code,
  refs https://github.com/timotheecour/Nim/issues/655
  and https://github.com/nim-lang/gtk2/pull/28; it's useful in other contexts.
  ]#
  var specs: seq[TSpec] = @[]
  for kind, dir in walkDir(testsDir):
    assert dir.startsWith(testsDir)
    let cat = dir[testsDir.len .. ^1]
    if kind == pcDir and cat notin specialCategories:
      for file in walkDirRec(testsDir / cat):
        if isTestFile(file):
          var spec: TSpec = default(TSpec)
          try:
            spec = parseSpec(file)
          except ValueError:
            # e.g. for `tests/navigator/tincludefile.nim` which have multiple
            # specs; this will be handled elsewhere
            echo "parseSpec raised ValueError for: '$1', assuming this will be handled outside of megatest" % file
            continue
          if isJoinableSpec(spec):
            specs.add spec

  proc cmp(a: TSpec, b: TSpec): auto = cmp(a.file, b.file)
  sort(specs, cmp = cmp) # reproducible order
  echo "joinable specs: ", specs.len

  if simulate:
    var s = "runJoinedTest: "
    for a in specs: s.add a.file & " "
    echo s
    return

  var megatest: string = ""
  # xxx (minor) put outputExceptedFile, outputGottenFile, megatestFile under here or `buildDir`
  var outDir = nimcacheDir(testsDir / "megatest", "", targetC)
  template toMarker(file, i): string =
    "megatest:processing: [$1] $2" % [$i, file]
  for i, runSpec in specs:
    let file = runSpec.file
    let file2 = outDir / ("megatest_a_$1.nim" % $i)
    # `include` didn't work with `trecmod2.nim`, so using `import`
    let code = "echo $1\nstatic: echo \"CT:\", $1\n" % [toMarker(file, i).quoted]
    createDir(file2.parentDir)
    writeFile(file2, code)
    megatest.add "import $1\nimport $2 as megatest_b_$3\n" % [file2.quoted, file.quoted, $i]

  let megatestFile = testsDir / "megatest.nim" # so it uses testsDir / "config.nims"
  writeFile(megatestFile, megatest)

  let root = getCurrentDir()

  var args = @["c", "--nimCache:" & outDir, "-d:testing", "-d:nimMegatest", "--listCmd",
              "--path:" & root]
  args.add options.parseCmdLine
  args.add megatestFile
  var (cmdLine, buf, exitCode) = execCmdEx2(command = compilerPrefix, args = args, input = "")
  if exitCode != 0:
    echo "$ " & cmdLine & "\n" & buf
    quit(failString & "megatest compilation failed")

  (buf, exitCode) = execCmdEx(megatestFile.changeFileExt(ExeExt).dup normalizeExe)
  if exitCode != 0:
    echo buf
    quit(failString & "megatest execution failed")

  const outputExceptedFile = "outputExpected.txt"
  const outputGottenFile = "outputGotten.txt"
  writeFile(outputGottenFile, buf)
  var outputExpected = ""
  for i, runSpec in specs:
    outputExpected.add toMarker(runSpec.file, i) & "\n"
    if runSpec.output.len > 0:
      outputExpected.add runSpec.output
      if not runSpec.output.endsWith "\n":
        outputExpected.add '\n'

  if buf != outputExpected:
    writeFile(outputExceptedFile, outputExpected)
    echo diffFiles(outputGottenFile, outputExceptedFile).output
    echo failString & "megatest output different, see $1 vs $2" % [outputGottenFile, outputExceptedFile]
    # outputGottenFile, outputExceptedFile not removed on purpose for debugging.
    quit 1
  else:
    echo "megatest output OK"


# ---------------------------------------------------------------------------

proc processCategory(r: var TResults, cat: Category,
                     options, testsDir: string,
                     runJoinableTests: bool) =
  let cat2 = cat.string.normalize
  var handled = false
  if isNimRepoTests():
    handled = true
    case cat2
    of "js":
      # only run the JS tests on Windows or Linux because Travis is bad
      # and other OSes like Haiku might lack nodejs:
      if not defined(linux) and isTravis:
        discard
      else:
        jsTests(r, cat, options)
    of "dll":
      dllTests(r, cat, options & " -d:nimDebugDlOpen")
    of "gc":
      gcTests(r, cat, options)
    of "debugger":
      debuggerTests(r, cat, options)
    of "manyloc":
      manyLoc r, cat, options
    of "threads":
      threadTests r, cat, options & " --threads:on"
    of "io":
      ioTests r, cat, options
    of "async":
      asyncTests r, cat, options
    of "lib":
      testStdlib(r, "lib/pure/", options, cat)
      testStdlib(r, "lib/packages/docutils/", options, cat)
    of "examples":
      compileExample(r, "examples/*.nim", options, cat)
      compileExample(r, "examples/gtk/*.nim", options, cat)
      compileExample(r, "examples/talk/*.nim", options, cat)
    of "nimble-packages":
      testNimblePackages(r, cat, options)
    of "niminaction":
      testNimInAction(r, cat, options)
    of "ic":
      icTests(r, testsDir / cat2, cat, options, isNavigatorTest=false)
    of "navigator":
      icTests(r, testsDir / cat2, cat, options, isNavigatorTest=true)
    of "untestable":
      # These require special treatment e.g. because they depend on a third party
      # dependency; see `trunner_special` which runs some of those.
      discard
    else:
      handled = false
  if not handled:
    case cat2
    of "megatest":
      runJoinedTest(r, cat, testsDir, options)
      if isNimRepoTests():
        runJoinedTest(r, cat, testsDir, options & " --mm:refc")
    else:
      var testsRun = 0
      var files: seq[string] = @[]
      for file in walkDirRec(testsDir &.? cat.string):
        if isTestFile(file): files.add file
      files.sort # give reproducible order
      for i, name in files:
        var test = makeTest(name, options, cat)
        if runJoinableTests or not isJoinableSpec(test.spec) or cat.string in specialCategories:
          discard "run the test"
        else:
          test.spec.err = reJoined
        testSpec r, test
        inc testsRun
      if testsRun == 0:
        const whiteListedDirs = ["deps", "htmldocs", "pkgs"]
          # `pkgs` because bug #16556 creates `pkgs` dirs and this can affect some users
          # that try an old version of choosenim.
        doAssert cat.string in whiteListedDirs,
          "Invalid category specified: '$#' not in whilelist: $#" % [cat.string, $whiteListedDirs]

proc processPattern(r: var TResults, pattern, options: string; simulate: bool) =
  var testsRun = 0
  if dirExists(pattern):
    for k, name in walkDir(pattern):
      if k in {pcFile, pcLinkToFile} and name.endsWith(".nim"):
        if simulate:
          echo "Detected test: ", name
        else:
          var test = makeTest(name, options, Category"pattern")
          testSpec r, test
        inc testsRun
  else:
    for name in walkPattern(pattern):
      if simulate:
        echo "Detected test: ", name
      else:
        var test = makeTest(name, options, Category"pattern")
        testSpec r, test
      inc testsRun
  if testsRun == 0:
    echo "no tests were found for pattern: ", pattern
