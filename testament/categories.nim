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

# included from tester.nim
# ---------------- ROD file tests ---------------------------------------------

const
  rodfilesDir = "tests/rodfiles"

proc delNimCache(filename, options: string) =
  for target in low(TTarget)..high(TTarget):
    let dir = nimcacheDir(filename, options, target)
    try:
      removeDir(dir)
    except OSError:
      echo "[Warning] could not delete: ", dir

proc runRodFiles(r: var TResults, cat: Category, options: string) =
  template test(filename: string, clearCacheFirst=false) =
    if clearCacheFirst: delNimCache(filename, options)
    testSpec r, makeTest(rodfilesDir / filename, options, cat, actionRun)


  # test basic recompilation scheme:
  test "hallo", true
  test "hallo"
  when false:
    # test incremental type information:
    test "hallo2"

  # test type converters:
  test "aconv", true
  test "bconv"

  # test G, A, B example from the documentation; test init sections:
  test "deada", true
  test "deada2"

  when false:
    # test method generation:
    test "bmethods", true
    test "bmethods2"

    # test generics:
    test "tgeneric1", true
    test "tgeneric2"

proc compileRodFiles(r: var TResults, cat: Category, options: string) =
  template test(filename: untyped, clearCacheFirst=true) =
    if clearCacheFirst: delNimCache(filename, options)
    testSpec r, makeTest(rodfilesDir / filename, options, cat)

  # test DLL interfacing:
  test "gtkex1", true
  test "gtkex2"

# --------------------- flags tests -------------------------------------------

proc flagTests(r: var TResults, cat: Category, options: string) =
  # --genscript
  const filename = "tests"/"flags"/"tgenscript"
  const genopts = " --genscript"
  let nimcache = nimcacheDir(filename, genopts, targetC)
  testSpec r, makeTest(filename, genopts, cat)

  when defined(windows):
    testExec r, makeTest(filename, " cmd /c cd " & nimcache &
                         " && compile_tgenscript.bat", cat)

  elif defined(posix):
    testExec r, makeTest(filename, " sh -c \"cd " & nimcache &
                         " && sh compile_tgenscript.sh\"", cat)

  # Run
  testExec r, makeTest(filename, " " & nimcache / "tgenscript", cat)

# --------------------- DLL generation tests ----------------------------------

proc safeCopyFile(src, dest: string) =
  try:
    copyFile(src, dest)
  except OSError:
    echo "[Warning] could not copy: ", src, " to ", dest

proc runBasicDLLTest(c, r: var TResults, cat: Category, options: string) =
  const rpath = when defined(macosx):
      " --passL:-rpath --passL:@loader_path"
    else:
      ""

  testSpec c, makeTest("lib/nimrtl.nim",
    options & " --app:lib -d:createNimRtl --threads:on", cat)
  testSpec c, makeTest("tests/dll/server.nim",
    options & " --app:lib -d:useNimRtl --threads:on" & rpath, cat)


  when defined(Windows):
    # windows looks in the dir of the exe (yay!):
    var nimrtlDll = DynlibFormat % "nimrtl"
    safeCopyFile("lib" / nimrtlDll, "tests/dll" / nimrtlDll)
  else:
    # posix relies on crappy LD_LIBRARY_PATH (ugh!):
    const libpathenv = when defined(haiku):
                         "LIBRARY_PATH"
                       else:
                         "LD_LIBRARY_PATH"
    var libpath = getEnv(libpathenv).string
    # Temporarily add the lib directory to LD_LIBRARY_PATH:
    putEnv(libpathenv, "tests/dll" & (if libpath.len > 0: ":" & libpath else: ""))
    defer: putEnv(libpathenv, libpath)
    var nimrtlDll = DynlibFormat % "nimrtl"
    safeCopyFile("lib" / nimrtlDll, "tests/dll" / nimrtlDll)

  testSpec r, makeTest("tests/dll/client.nim", options & " -d:useNimRtl --threads:on" & rpath,
                       cat, actionRun)

proc dllTests(r: var TResults, cat: Category, options: string) =
  # dummy compile result:
  var c = initResults()

  runBasicDLLTest c, r, cat, options
  runBasicDLLTest c, r, cat, options & " -d:release"
  when not defined(windows):
    # still cannot find a recent Windows version of boehm.dll:
    runBasicDLLTest c, r, cat, options & " --gc:boehm"
    runBasicDLLTest c, r, cat, options & " -d:release --gc:boehm"

# ------------------------------ GC tests -------------------------------------

proc gcTests(r: var TResults, cat: Category, options: string) =
  template testWithNone(filename: untyped) =
    testSpec r, makeTest("tests/gc" / filename, options &
                  " --gc:none", cat, actionRun)
    testSpec r, makeTest("tests/gc" / filename, options &
                  " -d:release --gc:none", cat, actionRun)

  template testWithoutMs(filename: untyped) =
    testSpec r, makeTest("tests/gc" / filename, options, cat, actionRun)
    testSpec r, makeTest("tests/gc" / filename, options &
                  " -d:release", cat, actionRun)
    testSpec r, makeTest("tests/gc" / filename, options &
                  " -d:release -d:useRealtimeGC", cat, actionRun)

  template testWithoutBoehm(filename: untyped) =
    testWithoutMs filename
    testSpec r, makeTest("tests/gc" / filename, options &
                  " --gc:markAndSweep", cat, actionRun)
    testSpec r, makeTest("tests/gc" / filename, options &
                  " -d:release --gc:markAndSweep", cat, actionRun)
  template test(filename: untyped) =
    testWithoutBoehm filename
    when not defined(windows) and not defined(android):
      # AR: cannot find any boehm.dll on the net, right now, so disabled
      # for windows:
      testSpec r, makeTest("tests/gc" / filename, options &
                    " --gc:boehm", cat, actionRun)
      testSpec r, makeTest("tests/gc" / filename, options &
                    " -d:release --gc:boehm", cat, actionRun)

  testWithoutBoehm "foreign_thr"
  test "gcemscripten"
  test "growobjcrash"
  test "gcbench"
  test "gcleak"
  test "gcleak2"
  testWithoutBoehm "gctest"
  testWithNone "gctest"
  test "gcleak3"
  test "gcleak4"
  # Disabled because it works and takes too long to run:
  #test "gcleak5"
  testWithoutBoehm "weakrefs"
  test "cycleleak"
  testWithoutBoehm "closureleak"
  testWithoutMs "refarrayleak"

  testWithoutBoehm "tlists"
  testWithoutBoehm "thavlak"

  test "stackrefleak"
  test "cyclecollector"

proc longGCTests(r: var TResults, cat: Category, options: string) =
  when defined(windows):
    let cOptions = "-ldl -DWIN"
  else:
    let cOptions = "-ldl"

  var c = initResults()
  # According to ioTests, this should compile the file
  testNoSpec c, makeTest("tests/realtimeGC/shared", options, cat, actionCompile)
  testC r, makeTest("tests/realtimeGC/cmain", cOptions, cat, actionRun)
  testSpec r, makeTest("tests/realtimeGC/nmain", options & "--threads: on", cat, actionRun)

# ------------------------- threading tests -----------------------------------

proc threadTests(r: var TResults, cat: Category, options: string) =
  template test(filename: untyped) =
    testSpec r, makeTest(filename, options, cat, actionRun)
    testSpec r, makeTest(filename, options & " -d:release", cat, actionRun)
    testSpec r, makeTest(filename, options & " --tlsEmulation:on", cat, actionRun)
  for t in os.walkFiles("tests/threads/t*.nim"):
    test(t)

# ------------------------- IO tests ------------------------------------------

proc ioTests(r: var TResults, cat: Category, options: string) =
  # We need readall_echo to be compiled for this test to run.
  # dummy compile result:
  var c = initResults()
  testSpec c, makeTest("tests/system/helpers/readall_echo", options, cat)
  testSpec r, makeTest("tests/system/tio", options, cat)

# ------------------------- async tests ---------------------------------------
proc asyncTests(r: var TResults, cat: Category, options: string) =
  template test(filename: untyped) =
    testSpec r, makeTest(filename, options, cat)
  for t in os.walkFiles("tests/async/t*.nim"):
    test(t)

# ------------------------- debugger tests ------------------------------------

proc debuggerTests(r: var TResults, cat: Category, options: string) =
  testNoSpec r, makeTest("tools/nimgrep", options & " --debugger:on", cat)

# ------------------------- JS tests ------------------------------------------

proc jsTests(r: var TResults, cat: Category, options: string) =
  template test(filename: untyped) =
    testSpec r, makeTest(filename, options & " -d:nodejs", cat,
                         actionRun), targetJS
    testSpec r, makeTest(filename, options & " -d:nodejs -d:release", cat,
                         actionRun), targetJS

  for t in os.walkFiles("tests/js/t*.nim"):
    test(t)
  for testfile in ["exception/texceptions", "exception/texcpt1",
                   "exception/texcsub", "exception/tfinally",
                   "exception/tfinally2", "exception/tfinally3",
                   "actiontable/tactiontable", "method/tmultimjs",
                   "varres/tvarres0", "varres/tvarres3", "varres/tvarres4",
                   "varres/tvartup", "misc/tints", "misc/tunsignedinc",
                   "async/tjsandnativeasync"]:
    test "tests/" & testfile & ".nim"

  for testfile in ["strutils", "json", "random", "times", "logging"]:
    test "lib/pure/" & testfile & ".nim"

# ------------------------- nim in action -----------

proc testNimInAction(r: var TResults, cat: Category, options: string) =
  let options = options & " --nilseqs:on"

  template test(filename: untyped, action: untyped) =
    testSpec r, makeTest(filename, options, cat, action)

  template testJS(filename: untyped) =
    testSpec r, makeTest(filename, options, cat, actionCompile), targetJS

  template testCPP(filename: untyped) =
    testSpec r, makeTest(filename, options, cat, actionCompile), targetCPP

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

  # Verify that the files have not been modified. Death shall fall upon
  # whoever edits these hashes without dom96's permission, j/k. But please only
  # edit when making a conscious breaking change, also please try to make your
  # commit message clear and notify me so I can easily compile an errata later.
  var testHashes: seq[string] = @[]

  for test in tests:
    testHashes.add(getMD5(readFile("tests" / test.addFileExt("nim")).string))

  const refHashes = @[
    "51afdfa84b3ca3d810809d6c4e5037ba", "30f07e4cd5eaec981f67868d4e91cfcf",
    "d14e7c032de36d219c9548066a97e846", "2e40bfd5daadb268268727da91bb4e81",
    "c5d3853ed0aba04bf6d35ba28a98dca0", "058603145ff92d46c009006b06e5b228",
    "7b94a029b94ddb7efafddd546c965ff6", "586d74514394e49f2370dfc01dd9e830",
    "e1901837b757c9357dc8d259fd0ef0f6", "097670c7ae12e825debaf8ec3995227b",
    "a8cb7b78cc78d28535ab467361db5d6e", "bfaec2816a1848991b530c1ad17a0184",
    "47cb71bb4c1198d6d29cdbee05aa10b9", "87e4436809f9d73324cfc4f57f116770",
    "7b7db5cddc8cf8fa9b6776eef1d0a31d", "e6e40219f0f2b877869b738737b7685e",
    "6532ee87d819f2605a443d5e94f9422a", "9a8fe78c588d08018843b64b57409a02",
    "03a801275b8b76b4170c870cd0da079d", "20bb7d3e2d38d43b0cb5fcff4909a4a8",
    "af6844598f534fab6942abfa4dfe9ab2", "2a7a17f84f6503d9bc89a5ab8feea127"
  ]
  doAssert testHashes == refHashes, "Nim in Action tests were changed."

  # Run the tests.
  for testfile in tests:
    test "tests/" & testfile & ".nim", actionCompile

  let jsFile = "tests/niminaction/Chapter8/canvas/canvas_test.nim"
  testJS jsFile

  let cppFile = "tests/niminaction/Chapter8/sfml/sfml_test.nim"
  testCPP cppFile




# ------------------------- manyloc -------------------------------------------
#proc runSpecialTests(r: var TResults, options: string) =
#  for t in ["lib/packages/docutils/highlite"]:
#    testSpec(r, t, options)

proc findMainFile(dir: string): string =
  # finds the file belonging to ".nim.cfg"; if there is no such file
  # it returns the some ".nim" file if there is only one:
  const cfgExt = ".nim.cfg"
  result = ""
  var nimFiles = 0
  for kind, file in os.walkDir(dir):
    if kind == pcFile:
      if file.endsWith(cfgExt): return file[.. ^(cfgExt.len+1)] & ".nim"
      elif file.endsWith(".nim"):
        if result.len == 0: result = file
        inc nimFiles
  if nimFiles != 1: result.setlen(0)

proc manyLoc(r: var TResults, cat: Category, options: string) =
  for kind, dir in os.walkDir("tests/manyloc"):
    if kind == pcDir:
      when defined(windows):
        if dir.endsWith"nake": continue
      if dir.endsWith"named_argument_bug": continue
      let mainfile = findMainFile(dir)
      if mainfile != "":
        testNoSpec r, makeTest(mainfile, options, cat)

proc compileExample(r: var TResults, pattern, options: string, cat: Category) =
  for test in os.walkFiles(pattern):
    testNoSpec r, makeTest(test, options, cat)

proc testStdlib(r: var TResults, pattern, options: string, cat: Category) =
  for test in os.walkFiles(pattern):
    let name = extractFilename(test)
    if name notin disabledFiles:
      let contents = readFile(test).string
      if contents.contains("when isMainModule"):
        testSpec r, makeTest(test, options, cat, actionRunNoSpec)
      else:
        testNoSpec r, makeTest(test, options, cat, actionCompile)

# ----------------------------- nimble ----------------------------------------
type PackageFilter = enum
  pfCoreOnly
  pfExtraOnly
  pfAll

var nimbleDir = getEnv("NIMBLE_DIR").string
if nimbleDir.len == 0: nimbleDir = getHomeDir() / ".nimble"
let
  nimbleExe = findExe("nimble")
  #packageDir = nimbleDir / "pkgs" # not used
  packageIndex = nimbleDir / "packages.json"

proc waitForExitEx(p: Process): int =
  var outp = outputStream(p)
  var line = newStringOfCap(120).TaintedString
  while true:
    if outp.readLine(line):
      discard
    else:
      result = peekExitCode(p)
      if result != -1: break
  close(p)

proc getPackageDir(package: string): string =
  ## TODO - Replace this with dom's version comparison magic.
  var commandOutput = execCmdEx("nimble path $#" % package)
  if commandOutput.exitCode != QuitSuccess:
    return ""
  else:
    result = commandOutput[0].string

iterator listPackages(filter: PackageFilter): tuple[name, url: string] =
  let packageList = parseFile(packageIndex)

  for package in packageList.items():
    let
      name = package["name"].str
      url = package["url"].str
      isCorePackage = "nim-lang" in normalize(url)
    case filter:
    of pfCoreOnly:
      if isCorePackage:
        yield (name, url)
    of pfExtraOnly:
      if not isCorePackage:
        yield (name, url)
    of pfAll:
      yield (name, url)

proc testNimblePackages(r: var TResults, cat: Category, filter: PackageFilter) =
  if nimbleExe == "":
    echo("[Warning] - Cannot run nimble tests: Nimble binary not found.")
    return

  if execCmd("$# update" % nimbleExe) == QuitFailure:
    echo("[Warning] - Cannot run nimble tests: Nimble update failed.")
    return

  let packageFileTest = makeTest("PackageFileParsed", "", cat)
  try:
    for name, url in listPackages(filter):
      var test = makeTest(name, "", cat)
      echo(url)
      let
        installProcess = startProcess(nimbleExe, "", ["install", "-y", name])
        installStatus = waitForExitEx(installProcess)
      installProcess.close
      if installStatus != QuitSuccess:
        r.addResult(test, targetC, "", "", reInstallFailed)
        continue

      let
        buildPath = getPackageDir(name).strip
        buildProcess = startProcess(nimbleExe, buildPath, ["build"])
        buildStatus = waitForExitEx(buildProcess)
      buildProcess.close
      if buildStatus != QuitSuccess:
        r.addResult(test, targetC, "", "", reBuildFailed)
      r.addResult(test, targetC, "", "", reSuccess)
    r.addResult(packageFileTest, targetC, "", "", reSuccess)
  except JsonParsingError:
    echo("[Warning] - Cannot run nimble tests: Invalid package file.")
    r.addResult(packageFileTest, targetC, "", "", reBuildFailed)


# ----------------------------------------------------------------------------

const AdditionalCategories = ["debugger", "examples", "lib"]

proc `&.?`(a, b: string): string =
  # candidate for the stdlib?
  result = if b.startswith(a): b else: a & b

#proc `&?.`(a, b: string): string = # not used
  # candidate for the stdlib?
  #result = if a.endswith(b): a else: a & b

proc processSingleTest(r: var TResults, cat: Category, options, test: string) =
  let test = "tests" & DirSep &.? cat.string / test
  let target = if cat.string.normalize == "js": targetJS else: targetC

  if existsFile(test): testSpec r, makeTest(test, options, cat), target
  else: echo "[Warning] - ", test, " test does not exist"

proc processCategory(r: var TResults, cat: Category, options: string) =
  case cat.string.normalize
  of "rodfiles":
    when false:
      compileRodFiles(r, cat, options)
      runRodFiles(r, cat, options)
  of "js":
    # only run the JS tests on Windows or Linux because Travis is bad
    # and other OSes like Haiku might lack nodejs:
    if not defined(linux) and isTravis:
      discard
    else:
      jsTests(r, cat, options)
  of "dll":
    dllTests(r, cat, options)
  of "flags":
    flagTests(r, cat, options)
  of "gc":
    gcTests(r, cat, options)
  of "longgc":
    longGCTests(r, cat, options)
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
    testStdlib(r, "lib/pure/*.nim", options, cat)
    testStdlib(r, "lib/packages/docutils/highlite", options, cat)
  of "examples":
    compileExample(r, "examples/*.nim", options, cat)
    compileExample(r, "examples/gtk/*.nim", options, cat)
    compileExample(r, "examples/talk/*.nim", options, cat)
  of "nimble-core":
    testNimblePackages(r, cat, pfCoreOnly)
  of "nimble-extra":
    testNimblePackages(r, cat, pfExtraOnly)
  of "nimble-all":
    testNimblePackages(r, cat, pfAll)
  of "niminaction":
    testNimInAction(r, cat, options)
  of "untestable":
    # We can't test it because it depends on a third party.
    discard # TODO: Move untestable tests to someplace else, i.e. nimble repo.
  else:
    var testsRun = 0
    for name in os.walkFiles("tests" & DirSep &.? cat.string / "t*.nim"):
      testSpec r, makeTest(name, options, cat)
      inc testsRun
    if testsRun == 0:
      echo "[Warning] - Invalid category specified \"", cat.string, "\", no tests were run"
