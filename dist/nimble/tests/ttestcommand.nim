# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

{.used.}

import unittest, os
import testscommon
from nimblepkg/common import cd

suite "test command":
  test "Runs passing unit tests":
    cd "testCommand/testsPass":
      # Pass flags to test #726, #757
      let (outp, exitCode) = execNimble("test", "-d:CUSTOM")
      check exitCode == QuitSuccess
      check outp.processOutput.inLines("First test")
      check outp.processOutput.inLines("Second test")
      check outp.processOutput.inLines("Third test")
      check outp.processOutput.inLines("Executing my func")

  test "Runs failing unit tests":
    cd "testCommand/testsFail":
      let (outp, exitCode) = execNimble("test")
      check exitCode == QuitFailure
      check outp.processOutput.inLines("First test")
      check outp.processOutput.inLines("Failing Second test")
      check(not outp.processOutput.inLines("Third test"))

  test "test command can be overriden":
    cd "testCommand/testOverride":
      let (outp, exitCode) = execNimble("-d:CUSTOM", "test", "--runflag")
      check exitCode == QuitSuccess
      check outp.processOutput.inLines("overriden")
      check outp.processOutput.inLines("true")

  test "certain files are ignored":
    cd "testCommand/testsIgnore":
      let (outp, exitCode) = execNimble("test")
      check exitCode == QuitSuccess
      check(not outp.processOutput.inLines("Should be ignored"))
      check outp.processOutput.inLines("First test")

  test "CWD is root of package":
    cd "testCommand/testsCWD":
      let (outp, exitCode) = execNimble("test")
      check exitCode == QuitSuccess
      check outp.processOutput.inLines(getCurrentDir())
