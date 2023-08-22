# Package

version       = "0.1.0"
author        = "Dominik Picheta"
description   = """Test package
with multi-line description
"""
license       = "BSD"

bin = @["nimscript"]

# Dependencies

requires "nim >= 0.12.1"

when thisDir().len != 0:
  echo "thisDirCT: ", thisDir()

task work, "test description":
  echo(5+5)

task c_test, "Testing `setCommand \"c\", \"nimscript.nim\"`":
  setCommand "c", "nimscript.nim"

task cr, "Testing `nimble c -r nimscript.nim` via setCommand":
  --r
  setCommand "c", "nimscript.nim"

task repeated, "Testing `nimble c nimscript.nim` with repeated flags":
  --define: foo
  --define: bar
  --define: "quoted"
  --define: "quoted\\\"with\\\"quotes"
  setCommand "c", "nimscript.nim"

task api, "Testing nimscriptapi module functionality":
  doAssert(findExe("nim").len != 0)
  echo("PKG_DIR: ", getPkgDir())
  echo("thisDir: ", thisDir())

before hooks:
  echo("First")

task hooks, "Testing the hooks":
  echo("Middle")

after hooks:
  echo("last")

before hooks2:
  return false

task hooks2, "Testing the hooks again":
  echo("Shouldn't happen")

before install:
  echo("Before PkgDir: ", getPkgDir())

after install:
  echo("After PkgDir: ", getPkgDir())

before build:
  echo("Before build")

after build:
  echo("After build")
