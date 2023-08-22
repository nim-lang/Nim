# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

{.used.}

import unittest, os, osproc, strutils
import testscommon
from nimblepkg/common import cd

suite "No global nim":
  let
    path = getEnv("PATH")
    nimbleCacheDir = getCurrentDir() / "localnimbledeps"
  when defined Linux:
    putEnv("PATH", findExe("git").parentDir)
  putEnv("NIMBLE_DIR", nimbleCacheDir)

  test "The nim from the lock file used":
    cd "nimdep":

      removeDir(nimbleCacheDir)

      let (output, exitCode) =
        execCmdEx(nimblePath & " version -y --lock-file=nimble-no-global-nim.lock")
      check exitCode == QuitSuccess

      let usingNim = when defined(Windows): "nim.exe for compilation" else: "bin/nim for compilation"
      check output.contains(usingNim)
      check output.contains("koch")

      # check not compiled again
      let (outputAfterInstalled, exitCodeAfterInstalled) =
        execCmdEx(nimblePath & " version -y --lock-file=nimble-no-global-nim.lock")
      check exitCodeAfterInstalled == QuitSuccess
      check not outputAfterInstalled.contains("koch")

  putEnv("PATH", path)
  delEnv("NIMBLE_DIR")
