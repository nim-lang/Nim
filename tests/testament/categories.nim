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
  nimcacheDir = rodfilesDir / "nimcache"

proc delNimCache() =
  try:
    removeDir(nimcacheDir)
  except OSError:
    echo "[Warning] could not delete: ", nimcacheDir
    
proc runRodFiles(r: var TResults, cat: Category, options: string) =
  template test(filename: expr): stmt =
    testSpec r, makeTest(rodfilesDir / filename, options, cat, actionRun)
  
  delNimCache()
  
  # test basic recompilation scheme:
  test "hallo"
  test "hallo"
  # test incremental type information:
  test "hallo2"
  delNimCache()
  
  # test type converters:
  test "aconv"
  test "bconv"
  delNimCache()
  
  # test G, A, B example from the documentation; test init sections:
  test "deada"
  test "deada2"
  delNimCache()
  
  # test method generation:
  test "bmethods"
  test "bmethods2"
  delNimCache()
  
  # test generics:
  test "tgeneric1"
  test "tgeneric2"
  delNimCache()

proc compileRodFiles(r: var TResults, cat: Category, options: string) =
  template test(filename: expr): stmt =
    testSpec r, makeTest(rodfilesDir / filename, options, cat)

  delNimCache()
  # test DLL interfacing:
  test "gtkex1"
  test "gtkex2"
  delNimCache()

# --------------------- DLL generation tests ----------------------------------

proc safeCopyFile(src, dest: string) =
  try:
    copyFile(src, dest)
  except OSError:
    echo "[Warning] could not copy: ", src, " to ", dest

proc runBasicDLLTest(c, r: var TResults, cat: Category, options: string) =
  testSpec c, makeTest("lib/nimrtl.nim",
    options & " --app:lib -d:createNimRtl", cat)
  testSpec c, makeTest("tests/dll/server.nim",
    options & " --app:lib -d:useNimRtl", cat)
  
  when defined(Windows): 
    # windows looks in the dir of the exe (yay!):
    var nimrtlDll = DynlibFormat % "nimrtl"
    safeCopyFile("lib" / nimrtlDll, "tests/dll" / nimrtlDll)
  else:
    # posix relies on crappy LD_LIBRARY_PATH (ugh!):
    var libpath = getEnv"LD_LIBRARY_PATH".string
    # Temporarily add the lib directory to LD_LIBRARY_PATH:
    putEnv("LD_LIBRARY_PATH", "lib:" & libpath)
    var serverDll = DynlibFormat % "server"
    safeCopyFile("tests/dll" / serverDll, "lib" / serverDll)
  
  testSpec r, makeTest("tests/dll/client.nim", options & " -d:useNimRtl", 
                       cat, actionRun)

proc dllTests(r: var TResults, cat: Category, options: string) =
  # dummy compile result:
  var c = initResults()
  
  runBasicDLLTest c, r, cat, options
  runBasicDLLTest c, r, cat, options & " -d:release"
  runBasicDLLTest c, r, cat, options & " --gc:boehm"
  runBasicDLLTest c, r, cat, options & " -d:release --gc:boehm"

# ------------------------------ GC tests -------------------------------------

proc gcTests(r: var TResults, cat: Category, options: string) =
  template testWithoutMs(filename: expr): stmt =
    testSpec r, makeTest("tests/gc" / filename, options, cat, actionRun)
    testSpec r, makeTest("tests/gc" / filename, options &
                  " -d:release", cat, actionRun)
    testSpec r, makeTest("tests/gc" / filename, options &
                  " -d:release -d:useRealtimeGC", cat, actionRun)

  template test(filename: expr): stmt =
    testWithoutMs filename
    testSpec r, makeTest("tests/gc" / filename, options &
                  " --gc:markAndSweep", cat, actionRun)
    testSpec r, makeTest("tests/gc" / filename, options &
                  " -d:release --gc:markAndSweep", cat, actionRun)

  test "growobjcrash"
  test "gcbench"
  test "gcleak"
  test "gcleak2"
  test "gctest"
  test "gcleak3"
  test "gcleak4"
  # Disabled because it works and takes too long to run:
  #test "gcleak5"
  test "weakrefs"
  test "cycleleak"
  test "closureleak"
  testWithoutMs "refarrayleak"
  
  test "stackrefleak"
  test "cyclecollector"

# ------------------------- threading tests -----------------------------------

proc threadTests(r: var TResults, cat: Category, options: string) =
  template test(filename: expr): stmt =
    testSpec r, makeTest("tests/threads" / filename, options, cat, actionRun)
    testSpec r, makeTest("tests/threads" / filename, options &
      " -d:release", cat, actionRun)
    testSpec r, makeTest("tests/threads" / filename, options &
      " --tlsEmulation:on", cat, actionRun)
  
  test "tactors"
  test "tactors2"
  test "threadex"
  # deactivated because output capturing still causes problems sometimes:
  #test "trecursive_actor"
  #test "threadring"
  #test "tthreadanalysis"
  #test "tthreadsort"
  test "tthreadanalysis2"
  #test "tthreadanalysis3"
  test "tthreadheapviolation1"

# ------------------------- IO tests ------------------------------------------

proc ioTests(r: var TResults, cat: Category, options: string) =
  # We need readall_echo to be compiled for this test to run.
  # dummy compile result:
  var c = initResults()
  testSpec c, makeTest("tests/system/helpers/readall_echo", options, cat)
  testSpec r, makeTest("tests/system/io", options, cat)

# ------------------------- debugger tests ------------------------------------

proc debuggerTests(r: var TResults, cat: Category, options: string) =
  testNoSpec r, makeTest("tools/nimgrep", options & " --debugger:on", cat)

# ------------------------- JS tests ------------------------------------------

proc jsTests(r: var TResults, cat: Category, options: string) =
  template test(filename: expr): stmt =
    testSpec r, makeTest(filename, options & " -d:nodejs", cat,
                         actionRun, targetJS)
    testSpec r, makeTest(filename, options & " -d:nodejs -d:release", cat,
                         actionRun, targetJS)
    
  for t in os.walkFiles("tests/js/t*.nim"):
    test(t)
  for testfile in ["exception/texceptions", "exception/texcpt1",
                   "exception/texcsub", "exception/tfinally",
                   "exception/tfinally2", "exception/tfinally3",
                   "actiontable/tactiontable", "method/tmultim1",
                   "method/tmultim3", "method/tmultim4"]:
    test "tests/" & testfile & ".nim"

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
      if file.endsWith(cfgExt): return file[.. -(cfgExt.len+1)] & ".nim"
      elif file.endsWith(".nim"):
        if result.len == 0: result = file
        inc nimFiles
  if nimFiles != 1: result.setlen(0)

proc manyLoc(r: var TResults, cat: Category, options: string) =
  for kind, dir in os.walkDir("tests/manyloc"):
    if kind == pcDir:
      let mainfile = findMainFile(dir)
      if mainfile != "":
        testNoSpec r, makeTest(mainfile, options, cat)

proc compileExample(r: var TResults, pattern, options: string, cat: Category) =
  for test in os.walkFiles(pattern):
    testNoSpec r, makeTest(test, options, cat)

proc testStdlib(r: var TResults, pattern, options: string, cat: Category) =
  for test in os.walkFiles(pattern):
    let contents = readFile(test).string
    if contents.contains("when isMainModule"):
      testSpec r, makeTest(test, options, cat, actionRun)
    else:
      testNoSpec r, makeTest(test, options, cat, actionCompile)

# ----------------------------- nimble ----------------------------------------
type PackageFilter = enum
  pfCoreOnly
  pfExtraOnly
  pfAll

let 
  nimbleExe = findExe("nimble")
  nimbleDir = getHomeDir() / ".nimble"
  packageDir = nimbleDir / "pkgs"
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
        r.addResult(test, "", "", reInstallFailed)
        continue

      let
        buildPath = getPackageDir(name).strip
        buildProcess = startProcess(nimbleExe, buildPath, ["build"])
        buildStatus = waitForExitEx(buildProcess)
      buildProcess.close
      if buildStatus != QuitSuccess:
        r.addResult(test, "", "", reBuildFailed)
      r.addResult(test, "", "", reSuccess)
    r.addResult(packageFileTest, "", "", reSuccess)
  except JsonParsingError:
    echo("[Warning] - Cannot run nimble tests: Invalid package file.")
    r.addResult(packageFileTest, "", "", reBuildFailed)


# ----------------------------------------------------------------------------

const AdditionalCategories = ["debugger", "examples", "lib"]

proc `&.?`(a, b: string): string =
  # candidate for the stdlib?
  result = if b.startswith(a): b else: a & b

proc `&?.`(a, b: string): string =
  # candidate for the stdlib?
  result = if a.endswith(b): a else: a & b

proc processCategory(r: var TResults, cat: Category, options: string) =
  case cat.string.normalize
  of "rodfiles":
    discard # Disabled for now
    #compileRodFiles(r, cat, options)
    #runRodFiles(r, cat, options)
  of "js":
    # XXX JS doesn't need to be special anymore
    jsTests(r, cat, options)
  of "dll":
    dllTests(r, cat, options)
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
  else:
    for name in os.walkFiles("tests" & DirSep &.? cat.string / "t*.nim"):
      testSpec r, makeTest(name, options, cat)
