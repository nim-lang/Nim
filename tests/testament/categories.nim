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

  when defined(linux):
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
    var libpath = getEnv"LD_LIBRARY_PATH".string
    # Temporarily add the lib directory to LD_LIBRARY_PATH:
    putEnv("LD_LIBRARY_PATH", "tests/dll" & (if libpath.len > 0: ":" & libpath else: ""))
    defer: putEnv("LD_LIBRARY_PATH", libpath)
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
  testSpec r, makeTest("tests/system/io", options, cat)

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
                   "exception/tunhandledexc",
                   "actiontable/tactiontable", "method/tmultim1",
                   "method/tmultim3", "method/tmultim4",
                   "varres/tvarres0", "varres/tvarres3", "varres/tvarres4",
                   "varres/tvartup", "misc/tints", "misc/tunsignedinc",
                   "async/tjsandnativeasync"]:
    test "tests/" & testfile & ".nim"

  for testfile in ["strutils", "json", "random", "times", "logging"]:
    test "lib/pure/" & testfile & ".nim"

# ------------------------- nim in action -----------

proc testNimInAction(r: var TResults, cat: Category, options: string) =
  template test(filename: untyped, action: untyped) =
    testSpec r, makeTest(filename, options, cat, action)

  template testJS(filename: untyped) =
    testSpec r, makeTest(filename, options, cat, actionCompile), targetJS

  template testCPP(filename: untyped) =
    testSpec r, makeTest(filename, options, cat, actionCompile), targetCPP

  let tests = [
    "niminaction/Chapter3/ChatApp/src/server",
    "niminaction/Chapter3/ChatApp/src/client",
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
    "niminaction/Chapter8/sdl/sdl_test",
    ]
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
    # XXX JS doesn't need to be special anymore
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
    for name in os.walkFiles("tests" & DirSep &.? cat.string / "t*.nim"):
      testSpec r, makeTest(name, options, cat)
