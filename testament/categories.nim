# Loading of test suite

import json, md5, parseopt, os, osproc, specs, sequtils, streams, strutils, types,
  runner, tables

when defined(windows):
  const
    # array of modules disabled from compilation test of stdlib.
    disabledFiles = ["coro.nim", "fsmonitor.nim"]
else:
  const
    # array of modules disabled from compilation test of stdlib.
    disabledFiles = ["-"]

proc makeId(filename: string): string =
  let (dir, file, _) = splitFile(filename)
  result = dir / file

proc makeTest(
    cat: Category,
    filename: string,
    action: TestAction = actionCompile,
    options: string = "",
    id: string = ""): Instance =
  Instance(
    id: makeId(filename) & id,
    cat: cat,
    filename: filename,
    action: action,
    target: targetC,
    options: options
  )

proc expandSpec(cat: Category, filename: string, options: string, spec: Spec,
    id: string = ""): Bundle =
  let targets = if spec.targets == {}: {targetC} else: spec.targets

  proc makeId(name: string, target: Target): string =
    result = filename
    if targets.card() > 1:
      result = result & "/" & $target
    result = result & id

  for target in targets:
    result.add Instance(
      id: makeId(filename, target),
      cat: cat,
      filename: filename,
      action: spec.action,
      target: target,
      options: options,
      cmd: spec.cmd,
      sortoutput: spec.sortoutput,
      expected: TestData(
        file: spec.file,
        outp: spec.outp,
        line: spec.line,
        column: spec.column,
        tfile: spec.tfile,
        tline: spec.tline,
        tcolumn: spec.tcolumn,
        exitCode: spec.exitCode,
        msg: spec.msg,
        ccodeCheck: spec.ccodeCheck,
        maxCodeSize: spec.maxCodeSize,
        res: spec.res,
        substr: spec.substr,
        nimout: spec.nimout
      )
    )

# ---------------- ROD file tests ---------------------------------------------

when false:
  # Disabled - left for inspiration in case something like rod files make it
  # back, though these test date back to an older version of testament
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

proc flagTests(cat: Category, options: string): seq[Bundle] =
  # --genscript
  const filename = "tests" / "flags" / "tgenscript.nim"
  const genopts = " --genscript"

  var bundle: Bundle

  bundle.add makeTest(cat, filename, options = genopts, id = "/gen")

  let nimcache = nimcacheDir(bundle[0].id)

  bundle.add when defined(windows):
    makeTest(cat, filename, actionExec,
      options = " cmd /c cd " & nimcache & " && compile_tgenscript.bat",
      id = "/compile")
  elif defined(posix):
    makeTest(cat, filename, actionExec,
      options = " sh -c \"cd " & nimcache & " && sh compile_tgenscript.sh\"",
      id = "/compile")

  # Run
  bundle.add makeTest(cat, filename, actionExec, " " & nimcache / "tgenscript",
    id = "/run")
  result.add bundle

# --------------------- DLL generation tests ----------------------------------

proc runBasicDLLTest(cat: Category, options: string): Bundle =
  const rpath =
    when defined(macosx):
      " --passL:-rpath --passL:@loader_path"
    elif not defined(windows):
      " --passL:-Wl,-rpath=lib/:tests/dll"
    else:
      ""
  const nimrtlDll = DynlibFormat % "nimrtl"

  result.add makeTest(cat, "lib/nimrtl.nim", actionCompile,
    options & " --app:lib -d:createNimRtl --threads:on")
  result.add makeTest(cat, "tests/dll/server.nim", actionCompile,
    options & " --app:lib -d:useNimRtl --threads:on" & rpath)

  when defined(Windows):
    # windows looks in the dir of the exe (yay!):
    result.add makeTest(cat, "lib/nimrtl.nim", actionCompile, options = "")
    result.add makeTest(cat, "lib/nimrtl.nim", actionExec,
        options = " copy lib\\" & nimrtlDll & " tests\\dll")
  else:
    result.add makeTest(cat, "lib/nimrtl.nim", actionCompile, options = "")
    result.add makeTest(cat, "lib/nimrtl.nim", actionExec,
        options = " cp lib/" & nimrtlDll & " tests/dll")

  let filename = "tests/dll/client.nim"
  for b in expandSpec(cat, filename, options & " -d:useNimRtl --threads:on" & rpath,
      parseSpec(filename, actionRun)):
    result.add b

proc dllTests(cat: Category, options: string): seq[Bundle] =
  var bundle: Bundle
  bundle.add runBasicDLLTest(cat, options)
  bundle.add runBasicDLLTest(cat, options & " -d:release")
  when not defined(windows):
    # still cannot find a recent Windows version of boehm.dll:
      bundle.add runBasicDLLTest(cat, options & " --gc:boehm")
      bundle.add runBasicDLLTest(cat, options & " -d:release --gc:boehm")
  result.add bundle

# ------------------------------ GC tests -------------------------------------

proc gcTests(cat: Category, options: string): seq[Bundle] =
  # one bundle per test, so they won't overwrite each others binaries..
  var res = initTable[string, Bundle]()

  template full(filename: string): string = "tests" / "gc" / filename & ".nim"
  template bundle(filename: string): untyped = res.mgetOrPut(filename, @[])

  template testWithNone(filename: string) =
    let spec = parseSpec(filename.full, actionRun)
    bundle(filename).add expandSpec(cat, filename.full,
      options & " --gc:none", spec, id = "/none")
    bundle(filename).add expandSpec(cat, filename.full,
      options & " -d:release --gc:none", spec, id = "/none/rel")

  template testWithoutMs(filename: string) =
    let spec = parseSpec(filename.full, actionRun)
    bundle(filename).add expandSpec(cat, filename.full, options, spec)
    bundle(filename).add expandSpec(cat, filename.full,
      options & " -d:release", spec, id = "/rel")
    bundle(filename).add expandSpec(cat, filename.full,
      options & " -d:release -d:useRealtimeGC", spec, id = "/rel/real")

  template testWithoutBoehm(filename: string) =
    testWithoutMs filename
    let spec = parseSpec(filename.full, actionRun)
    bundle(filename).add expandSpec(cat, filename.full,
      options & " --gc:markAndSweep", spec, id = "/ms")
    bundle(filename).add expandSpec(cat, filename.full,
      options & " -d:release --gc:markAndSweep", spec, id = "/ms/rel")

  template test(filename: string) =
    testWithoutBoehm filename
    when not defined(windows) and not defined(android):
      # AR: cannot find any boehm.dll on the net, right now, so disabled
      # for windows:
      let spec = parseSpec(filename.full, actionRun)
      bundle(filename).add expandSpec(cat, filename.full,
        options & " --gc:boehm", spec, id = "/boehm")
      bundle(filename).add expandSpec(cat, filename.full,
        options & " -d:release --gc:boehm", spec, id = "/hoehm/rel")

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

  for k, v in res: result.add v

proc longGCTests(cat: Category, options: string): seq[Bundle] =
  when defined(windows):
    let cOptions = "-ldl -DWIN"
  else:
    let cOptions = "-ldl"

  var bundle: Bundle

  # According to ioTests, this should compile the file
  bundle.add makeTest(cat, "tests/realtimeGC/shared", actionCompile, options)
  bundle.add makeTest(cat, "tests/realtimeGC/cmain", actionRunC, cOptions)
  bundle.add makeTest(cat, "tests/realtimeGC/nmain", actionRun,
    options & "--threads: on")
  result.add bundle

# ------------------------- threading tests -----------------------------------

proc threadTests(cat: Category, options: string): seq[Bundle] =
  template test(filename: untyped) =
    var bundle: Bundle
    bundle.add expandSpec(cat, filename, options, parseSpec(filename, actionRun))
    bundle.add expandSpec(cat, filename, options & " -d:release",
      parseSpec(filename, actionRun), id = "/rel")
    bundle.add expandSpec(cat, filename, options & " --tlsEmulation:on",
      parseSpec(filename, actionRun), id = "/tls")
    result.add bundle
  for t in os.walkFiles("tests/threads/t*.nim"):
    test(t)

# ------------------------- IO tests ------------------------------------------

proc ioTests(cat: Category, options: string): seq[Bundle] =
  # We need readall_echo to be compiled for this test to run.
  var bundle: Bundle
  bundle.add expandSpec(cat, "tests/system/helpers/readall_echo.nim", options,
    parseSpec("tests/system/helpers/readall_echo.nim"))
  bundle.add expandSpec(cat, "tests/system/io.nim", options,
    parseSpec("tests/system/io.nim"))
  result.add bundle

# ------------------------- debugger tests ------------------------------------

proc debuggerTests(cat: Category, options: string): seq[Bundle] =
  var bundle: Bundle
  bundle.add makeTest(cat, "tools/nimgrep.nim", actionRunNoSpec, options & " --debugger:on")
  result.add bundle

# ------------------------- JS tests ------------------------------------------

proc jsTests(cat: Category, options: string): seq[Bundle] =
  template test(filename: untyped) =
    var bundle: Bundle
    bundle.add expandSpec(cat, filename, options & " -d:nodejs",
      parseSpec(filename, actionRun, {targetJS}))
    bundle.add expandSpec(cat, filename, options & " -d:nodejs -d:release",
      parseSpec(filename, actionRun, {targetJS}))
    result.add bundle

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

proc testNimInAction(cat: Category, options: string): seq[Bundle] =
  let options = options & " --nilseqs:on"

  template test(filename: untyped, action: untyped) =
    result.add expandSpec(cat, filename, options, parseSpec(filename, action))

  template testJS(filename: untyped) =
    result.add expandSpec(cat, filename, options,
      parseSpec(filename, actionCompile, {targetJS}))

  template testCPP(filename: untyped) =
    result.add expandSpec(cat, filename, options,
      parseSpec(filename, actionCompile, {targetCPP}))

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

proc manyLoc(cat: Category, options: string): seq[Bundle] =
  for kind, dir in os.walkDir("tests/manyloc"):
    if kind == pcDir:
      when defined(windows):
        if dir.endsWith"nake": continue
      if dir.endsWith"named_argument_bug": continue
      let mainfile = findMainFile(dir)
      if mainfile != "":
        var bundle: Bundle
        bundle.add makeTest(cat, mainfile, actionRunNoSpec, options)
        result.add bundle


proc compileExample(pattern, options: string, cat: Category): seq[Bundle] =
  for test in os.walkFiles(pattern):
    var bundle: Bundle
    bundle.add makeTest(cat, test, actionRunNoSpec, options)
    result.add bundle

proc testStdlib(pattern, options: string, cat: Category): seq[Bundle] =
  for test in os.walkFiles(pattern):
    let name = extractFilename(test)
    if name notin disabledFiles:
      let contents = readFile(test).string
      var bundle: Bundle
      if contents.contains("when isMainModule"):
        bundle.add makeTest(cat, test, actionRunNoSpec, options)
      else:
        bundle.add makeTest(cat, test, actionCompile, options)
      result.add bundle

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
  packageIndex = nimbleDir / "packages_official.json"

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
    if "name" notin package or "url" notin package:
      continue
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

proc testNimblePackages(cat: Category, filter: PackageFilter): seq[Bundle] =
  if nimbleExe == "":
    echo("[Warning] - Cannot run nimble tests: Nimble binary not found.")
    return

  if execCmd("$# update" % nimbleExe) == QuitFailure:
    echo("[Warning] - Cannot run nimble tests: Nimble update failed.")
    return

  try:
    for name, url in listPackages(filter):
      let buildPath = getPackageDir(name).strip

      var bundle: Bundle
      bundle.add makeTest(cat, name, actionExec,
        " " & nimbleExe & " install -y " & name, id = "/install")
      bundle.add makeTest(cat, name, actionExec,
        " cd " & buildPath & " ; " & nimbleExe & " build -y " & name, id = "/build")
      result.add bundle

  except JsonParsingError:
    echo("[Warning] - Cannot run nimble tests: Invalid package file.")


# ----------------------------------------------------------------------------

const AdditionalCategories = ["debugger", "examples", "lib"]

proc targetFilter*(targets: set[Target]): RunFilter =
  (proc(inst: Instance): bool = inst.target in targets)

proc categoryGen*(cat: Category, options: string): seq[Bundle] =
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
      result = jsTests(cat, options)
  of "dll":
    result = dllTests(cat, options)
  of "flags":
    result = flagTests(cat, options)
  of "gc":
    result = gcTests(cat, options)
  of "longgc":
    result = longGCTests(cat, options)
  of "debugger":
    result = debuggerTests(cat, options)
  of "manyloc":
    result = manyLoc(cat, options)
  of "threads":
    result = threadTests(cat, options & " --threads:on")
  of "io":
    result = ioTests(cat, options)
  of "lib":
    result.add testStdlib("lib/pure/*.nim", options, cat)
    result.add testStdlib("lib/packages/docutils/highlite", options, cat)
  of "examples":
    result.add compileExample("examples/*.nim", options, cat)
    result.add compileExample("examples/gtk/*.nim", options, cat)
    result.add compileExample("examples/talk/*.nim", options, cat)
  of "nimble-core":
    result = testNimblePackages(cat, pfCoreOnly)
  of "nimble-extra":
    result = testNimblePackages(cat, pfExtraOnly)
  of "nimble-all":
    result = testNimblePackages(cat, pfAll)
  of "niminaction":
    result = testNimInAction(cat, options)
  of "untestable":
    # We can't test it because it depends on a third party.
    discard # TODO: Move untestable tests to someplace else, i.e. nimble repo.
  else:
    var testsRun = 0
    for filename in os.walkFiles("tests" / cat.string / "t*.nim"):
      result.add expandSpec(cat, filename, options, parseSpec(filename))
      inc testsRun
    if testsRun == 0:
      echo "[Warning] - Invalid category specified \"", cat.string, "\", no tests were run"

proc allGen*(options: string): seq[Bundle] =
  let testsDir = "tests" & DirSep
  for kind, dir in walkDir(testsDir):
    assert testsDir.startsWith(testsDir)
    let cat = dir[testsDir.len .. ^1]
    if kind == pcDir and cat notin ["testament", "testdata", "nimcache"]:
      for b in categoryGen(cat.Category, options): result.add b

  for cat in AdditionalCategories:
    for b in categoryGen(cat.Category, options): result.add b
