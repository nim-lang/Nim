# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

{.used.}

import unittest, os, strutils
import testscommon
from nimblepkg/common import cd

suite "nimscript":
  test "can install nimscript package":
    cleanDir installDir
    cd "nimscript":
      let
        nim = findExe("nim").relativePath(base = getCurrentDir())
      check execNimbleYes(["install", "--nim:" & nim]).exitCode == QuitSuccess

  test "before/after install pkg dirs are correct":
    cleanDir installDir
    cd "nimscript":
      let (output, exitCode) = execNimbleYes(["install", "--nim:nim"])
      check exitCode == QuitSuccess
      check output.contains("Before build")
      check output.contains("After build")
      let lines = output.strip.processOutput()
      for line in lines:
        if lines[3].startsWith("Before PkgDir:"):
          check line.endsWith("tests" / "nimscript")
      check lines[^1].startsWith("After PkgDir:")
      let packageDir = getPackageDir(pkgsDir, "nimscript-0.1.0")
      check lines[^1].strip(trailing = true).endsWith(packageDir)

  test "before/after on build":
    cd "nimscript":
      let (output, exitCode) = execNimble([
        "build", "--nim:" & findExe("nim"), "--silent"])
      check exitCode == QuitSuccess
      check output.contains("Before build")
      check output.contains("After build")
      check not output.contains("Verifying")

  test "can execute nimscript tasks":
    cd "nimscript":
      let (output, exitCode) = execNimble("work")
      let lines = output.strip.processOutput()
      check exitCode == QuitSuccess
      check lines[^1] == "10"

  test "can use nimscript's setCommand":
    cd "nimscript":
      let (output, exitCode) = execNimble("cTest")
      let lines = output.strip.processOutput()
      check exitCode == QuitSuccess
      check "Execution finished".normalize in lines[^1].normalize

  test "can use nimscript's setCommand with flags":
    cd "nimscript":
      let (output, exitCode) = execNimble("--debug", "cr")
      let lines = output.strip.processOutput()
      check exitCode == QuitSuccess
      check inLines(lines, "Hello World")

  test "can use nimscript with repeated flags (issue #329)":
    cd "nimscript":
      let (output, exitCode) = execNimble("--debug", "repeated")
      let lines = output.strip.processOutput()
      check exitCode == QuitSuccess
      var found = false
      for line in lines:
        if line.contains("--define:foo"):
          found = true
      check found == true

  test "can list nimscript tasks":
    cd "nimscript":
      let (output, exitCode) = execNimble("tasks")
      check "work".normalize in output.normalize
      check "test description".normalize in output.normalize
      check exitCode == QuitSuccess

  test "can use pre/post hooks":
    cd "nimscript":
      let (output, exitCode) = execNimble("hooks")
      let lines = output.strip.processOutput()
      check exitCode == QuitSuccess
      check inLines(lines, "First")
      check inLines(lines, "middle")
      check inLines(lines, "last")

  test "pre hook can prevent action":
    cd "nimscript":
      let (output, exitCode) = execNimble("hooks2")
      let lines = output.strip.processOutput()
      check exitCode == QuitFailure
      check(not inLines(lines, "Shouldn't happen"))
      check inLines(lines, "Hook prevented further execution")

  test "nimble script api":
    cd "nimscript":
      let (output, exitCode) = execNimble("api")
      let lines = output.strip.processOutput()
      check exitCode == QuitSuccess
      check inLines(lines, "thisDirCT: " & getCurrentDir())
      check inLines(lines, "PKG_DIR: " & getCurrentDir())
      check inLines(lines, "thisDir: " & getCurrentDir())

  test "nimscript evaluation error message":
    cd "invalidPackage":
      let (output, exitCode) = execNimble("check")
      let lines = output.strip.processOutput()
      check(lines.inLines("undeclared identifier: 'thisFieldDoesNotExist'"))
      check exitCode == QuitFailure

  test "can accept short flags (#329)":
    cd "nimscript":
      let (_, exitCode) = execNimble("c", "-d:release", "nimscript.nim")
      check exitCode == QuitSuccess
