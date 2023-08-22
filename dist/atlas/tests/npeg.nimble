# Package

version       = "0.24.1"
author        = "Ico Doornekamp"
description   = "a PEG library"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]

# Dependencies

requires "nim >= 0.19.0"

# Test

task test, "Runs the test suite":
  exec "nimble testc && nimble testcpp && nimble testarc && nimble testjs"

task testc, "C tests":
  exec "nim c -r tests/tests.nim"

task testcpp, "CPP tests":
  exec "nim cpp -r tests/tests.nim"

task testjs, "JS tests":
  exec "nim js -r tests/tests.nim"

task testdanger, "Runs the test suite in danger mode":
  exec "nim c -d:danger -r tests/tests.nim"

task testwin, "Mingw tests":
  exec "nim c -d:mingw tests/tests.nim && wine tests/tests.exe"

task test32, "32 bit tests":
  exec "nim c --cpu:i386 --passC:-m32 --passL:-m32 tests/tests.nim && tests/tests"

task testall, "Test all":
  exec "nimble test && nimble testcpp && nimble testdanger && nimble testjs && nimble testwin"

when (NimMajor, NimMinor) >= (1, 1):
  task testarc, "--gc:arc tests":
    exec "nim c --gc:arc -r tests/tests.nim"
else:
  task testarc, "--gc:arc tests":
    exec "true"

task perf, "Test performance":
  exec "nim cpp -r -d:danger tests/performance.nim"
