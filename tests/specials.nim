#
#
#            Nimrod Tester
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Include for the tester that contains test suites that test special features
## of the compiler.

# ---------------- ROD file tests ---------------------------------------------

const
  rodfilesDir = "tests/rodfiles"

proc delNimCache() = removeDir(rodfilesDir / "nimcache")
proc plusCache(options: string): string = return options & " --symbolFiles:on"

proc runRodFiles(r: var TResults, options: string) =
  template test(filename: expr): stmt =
    runSingleTest(r, rodfilesDir / filename, options)
  
  var options = options.plusCache
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

proc compileRodFiles(r: var TResults, options: string) =
  template test(filename: expr): stmt =
    compileSingleTest(r, rodfilesDir / filename, options)
    
  var options = options.plusCache
  delNimCache()
  # test DLL interfacing:
  test "gtkex1"
  test "gtkex2"
  delNimCache()

# --------------------- DLL generation tests ----------------------------------

proc runBasicDLLTest(c, r: var TResults, options: string) =
  compileSingleTest c, "lib/nimrtl.nim", options & " --app:lib -d:createNimRtl"
  compileSingleTest c, "tests/dll/server.nim", 
    options & " --app:lib -d:useNimRtl"
  
  when defined(Windows): 
    # windows looks in the dir of the exe (yay!):
    var nimrtlDll = DynlibFormat % "nimrtl"
    copyFile("lib" / nimrtlDll, "tests/dll" / nimrtlDll)
  else:
    # posix relies on crappy LD_LIBRARY_PATH (ugh!):
    var libpath = getenv"LD_LIBRARY_PATH".string
    if peg"\i '/nimrod' (!'/')* '/lib'" notin libpath:
      echo "[Warning] insufficient LD_LIBRARY_PATH"
    var serverDll = DynlibFormat % "server"
    copyFile("tests/dll" / serverDll, "lib" / serverDll)
  
  runSingleTest r, "tests/dll/client.nim", options & " -d:useNimRtl"

proc runDLLTests(r: var TResults, options: string) =
  # dummy compile result:
  var c = initResults()
  
  runBasicDLLTest c, r, options
  runBasicDLLTest c, r, options & " -d:release"
  runBasicDLLTest c, r, options & " --gc:boehm"
  runBasicDLLTest c, r, options & " -d:release --gc:boehm"
  
# ------------------------------ GC tests -------------------------------------

proc runGcTests(r: var TResults, options: string) =
  template test(filename: expr): stmt =
    runSingleTest(r, "tests/gc" / filename, options)
    runSingleTest(r, "tests/gc" / filename, options & " -d:release")
  
  test "gcbench"
  test "gcleak"
  test "gcleak2"
  test "gctest"
  # disabled for now as it somehow runs very slowly ('delete' bug?) but works:
  test "gcleak3"
  

# ------------------------- threading tests -----------------------------------

proc runThreadTests(r: var TResults, options: string) =
  template test(filename: expr): stmt =
    runSingleTest(r, "tests/threads" / filename, options)
    runSingleTest(r, "tests/threads" / filename, options & " -d:release")
    runSingleTest(r, "tests/threads" / filename, options & " --tlsEmulation:on")
  
  test "tactors"
  test "threadex"
  test "trecursive_actor"
  #test "threadring"
  #test "tthreadanalysis"
  #test "tthreadsort"

proc rejectThreadTests(r: var TResults, options: string) =
  rejectSingleTest(r, "tests/threads/tthreadanalysis2", options)
  rejectSingleTest(r, "tests/threads/tthreadanalysis3", options)
  rejectSingleTest(r, "tests/threads/tthreadheapviolation1", options)

# ------------------------- IO tests -----------------------------------

proc runIOTests(r: var TResults, options: string) =
  compileSingleTest(r, "tests/system/helpers/readall_echo.nim", options)
  runSingleTest(r, "tests/system/io", options)

# ------------------------- register special tests here -----------------------
proc runSpecialTests(r: var TResults, options: string) =
  runRodFiles(r, options)
  runDLLTests(r, options)
  runGCTests(r, options)
  runThreadTests(r, options & " --threads:on")
  runIOTests(r, options)

proc rejectSpecialTests(r: var TResults, options: string) =
  rejectThreadTests(r, options)

proc compileSpecialTests(r: var TResults, options: string) =
  compileRodFiles(r, options)

  compileSingleTest(r, "compiler/c2nim/c2nim.nim", options)
  compileSingleTest(r, "compiler/pas2nim/pas2nim.nim", options)

