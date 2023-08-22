# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

{.used.}

import unittest, os, strutils
import testscommon

from nimblepkg/common import cd

suite "reverse dependencies":
  test "basic test":
    cd "revdep/mydep":
      verify execNimbleYes("install")

    cd "revdep/pkgWithDep":
      verify execNimbleYes("install")

    verify execNimbleYes("remove", "pkgA")
    verify execNimbleYes("remove", "mydep")

  test "revdep fail test":
    cd "revdep/mydep":
      verify execNimbleYes("install")

    cd "revdep/pkgWithDep":
      verify execNimbleYes("install")

    let (output, exitCode) = execNimble("uninstall", "mydep")
    checkpoint output
    check output.processOutput.inLines("cannot uninstall mydep")
    check exitCode == QuitFailure

  test "revdep -i test":
    cd "revdep/mydep":
      verify execNimbleYes("install")

    cd "revdep/pkgWithDep":
      verify execNimbleYes("install")

    verify execNimbleYes("remove", "mydep", "-i")

  test "issue #373":
    cd "revdep/mydep":
      verify execNimbleYes("install")

    cd "revdep/pkgWithDep":
      verify execNimbleYes("install")

    verify execNimbleYes("remove", "pkgA")

    cd "revdep/pkgNoDep":
      verify execNimbleYes("install")

    verify execNimbleYes("remove", "mydep")

  test "remove skips packages with revDeps (#504)":
    var (output, exitCode) = execNimbleYes(
      "install", "nimboost@0.5.5", "nimfp@0.4.4")
    check exitCode == QuitSuccess

    (output, exitCode) = execNimble("uninstall", "nimboost", "nimfp", "-n")
    var lines = output.strip.processOutput()
    check inLines(lines, "Cannot uninstall nimboost")

    (output, exitCode) = execNimbleYes("uninstall", "nimfp", "nimboost")
    lines = output.strip.processOutput()
    check (not inLines(lines, "Cannot uninstall nimboost"))

    check execNimble("path", "nimboost").exitCode != QuitSuccess
    check execNimble("path", "nimfp").exitCode != QuitSuccess
