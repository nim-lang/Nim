# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

{.used.}

import unittest, strutils, os, strformat
import testscommon

from nimblepkg/displaymessages import cannotUninstallPkgMsg
from nimblepkg/common import cd
from nimblepkg/version import newVersion

suite "uninstall":
  test "cannot install packagebin2 in --offline mode":
    cleanDir(installDir)
    let args = ["--offline", "install", pkgBin2Url]
    let (output, exitCode) = execNimbleYes(args)
    check exitCode != QuitSuccess
    check output.contains("Cannot download in offline mode.")

  test "can install packagebin2":
    cleanDir(installDir)
    let args = ["install", pkgBin2Url]
    check execNimbleYes(args).exitCode == QuitSuccess

  proc cannotSatisfyMsg(v1, v2: string): string =
     &"Cannot satisfy the dependency on PackageA {v1} and PackageA {v2}"

  test "can reject same version dependencies":
    cleanDir(installDir)
    let (outp, exitCode) = execNimbleYes("install", pkgBinUrl)
    # We look at the error output here to avoid out-of-order problems caused by
    # stderr output being generated and flushed without first flushing stdout
    let ls = outp.strip.processOutput()
    check exitCode != QuitSuccess
    check ls.inLines(cannotSatisfyMsg("0.2.0", "0.5.0")) or
          ls.inLines(cannotSatisfyMsg("0.5.0", "0.2.0"))

  proc setupIssue27Packages() =
    # Install b
    cd "issue27/b":
      check execNimbleYes("install").exitCode == QuitSuccess
    # Install a
    cd "issue27/a":
      check execNimbleYes("install").exitCode == QuitSuccess
    cd "issue27":
      check execNimbleYes("install").exitCode == QuitSuccess

  test "issue #27":
    setupIssue27Packages()

  test "can uninstall":
    # setup test environment
    cleanDir(installDir)
    setupIssue27Packages()
    check execNimbleYes("install", &"{pkgAUrl}@0.2").exitCode == QuitSuccess
    check execNimbleYes("install", &"{pkgAUrl}@0.5").exitCode == QuitSuccess
    check execNimbleYes("install", &"{pkgAUrl}@0.6").exitCode == QuitSuccess
    check execNimbleYes("install", pkgBin2Url).exitCode == QuitSuccess
    check execNimbleYes("install", pkgBUrl).exitCode == QuitSuccess
    cd "nimscript": check execNimbleYes("install").exitCode == QuitSuccess

    block:
      let (outp, exitCode) = execNimbleYes("uninstall", "issue27b")
      check exitCode != QuitSuccess
      var ls = outp.strip.processOutput()
      let pkg27ADir = getPackageDir(pkgsDir, "issue27a-0.1.0", false)
      let expectedMsg = cannotUninstallPkgMsg(
        "issue27b", newVersion("0.1.0"), @[pkg27ADir])
      check ls.inLinesOrdered(expectedMsg)

      check execNimbleYes("uninstall", "issue27").exitCode == QuitSuccess
      check execNimbleYes("uninstall", "issue27a").exitCode == QuitSuccess

    # Remove Package*
    check execNimbleYes("uninstall", "PackageA@0.5").exitCode == QuitSuccess

    let (outp, exitCode) = execNimbleYes("uninstall", "PackageA")
    check exitCode != QuitSuccess
    let ls = outp.processOutput()
    let
      pkgBin2Dir = getPackageDir(pkgsDir, "packagebin2-0.1.0", false)
      pkgBDir = getPackageDir(pkgsDir, "packageb-0.1.0", false)
      expectedMsgForPkgA0dot6 = cannotUninstallPkgMsg(
        "PackageA", newVersion("0.6.0"), @[pkgBin2Dir])
      expectedMsgForPkgA0dot2 = cannotUninstallPkgMsg(
        "PackageA", newVersion("0.2.0"), @[pkgBDir])
    check ls.inLines(expectedMsgForPkgA0dot6)
    check ls.inLines(expectedMsgForPkgA0dot2)

    check execNimbleYes("uninstall", "PackageBin2").exitCode == QuitSuccess

    # Case insensitive
    check execNimbleYes("uninstall", "packagea").exitCode == QuitSuccess
    check execNimbleYes("uninstall", "PackageA").exitCode != QuitSuccess

    # Remove the rest of the installed packages.
    check execNimbleYes("uninstall", "PackageB").exitCode == QuitSuccess

    check execNimbleYes("uninstall", "PackageA@0.2", "issue27b").exitCode ==
        QuitSuccess
    check(not dirExists(pkgsDir / "PackageA-0.2.0"))

    check execNimbleYes("uninstall", "nimscript").exitCode == QuitSuccess
