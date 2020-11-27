
mode = ScriptMode.Whatif

exec "gcc -v"

--forceBuild
--path: "../friends"

warning("uninit", off)

block: # supported syntaxes for hint,warning,switch
  --hint:processing
  hint("processing", on)
  hint("processing", off)
  switch("hint", "processing")
  switch("hint", "processing:on")
  switch("hint", "processing:off")
  switch("hint", "[processing]")
  switch("hint", "[processing]:on")
  switch("hint", "[processing]:off") # leave it off

  --warning:UnusedImport
  switch("warning", "UnusedImport:off")
  switch("warning", "UnusedImport:on")
  switch("warning", "[UnusedImport]:off")
  switch("warning", "[UnusedImport]:on")
  switch("warning", "[UnusedImport]")
  switch("warning", "UnusedImport") # leave it on

#--verbosity:2
patchFile("stdlib", "math", "mymath")

task listDirs, "lists every subdirectory":
  for x in listDirs("."):
    echo "DIR ", x

task default, "default target":
  --define: definedefine
  setCommand "c"

# bug #6327
doAssert(existsEnv("dummy") == false)

# issue #7283
putEnv("dummy", "myval")
doAssert(existsEnv("dummy"))
doAssert(getEnv("dummy") == "myval")
delEnv("dummy")
doAssert(existsEnv("dummy") == false)

# issue #7393
let wd = getCurrentDir()
cd("..")
assert wd != getCurrentDir()
cd(wd)
assert wd == getCurrentDir()

when false:
  # this doesn't work in a 'koch testintall' environment
  assert findExe("nim") != ""

# general tests
mode = ScriptMode.Verbose

assert getCommand() == "c"
setCommand("cpp")
assert getCommand() == "cpp"
setCommand("c")

assert cmpic("HeLLO", "hello") == 0

assert fileExists("tests/newconfig/tfoo.nims") == true
assert dirExists("tests") == true

assert fileExists("tests/newconfig/tfoo.nims") == true
assert dirExists("tests") == true

discard selfExe()

when defined(windows):
  assert toExe("nim") == "nim.exe"
  assert toDll("nim") == "nim.dll"
else:
  assert toExe("nim") == "nim"
  assert toDll("nim") == "libnim.so"

rmDir("tempXYZ")
doAssertRaises(OSError):
  rmDir("tempXYZ", checkDir = true)
assert dirExists("tempXYZ") == false
mkDir("tempXYZ")
assert dirExists("tempXYZ") == true
assert fileExists("tempXYZ/koch.nim") == false

when false:
  # this doesn't work in a 'koch testintall' environment
  cpFile("koch.nim", "tempXYZ/koch.nim")
  assert fileExists("tempXYZ/koch.nim") == true
  cpDir("nimsuggest", "tempXYZ/.")
  assert dirExists("tempXYZ/tests") == true
  assert fileExists("tempXYZ/nimsuggest.nim") == true
  rmFile("tempXYZ/koch.nim")
  assert fileExists("tempXYZ/koch.nim") == false

rmDir("tempXYZ")
assert dirExists("tempXYZ") == false
