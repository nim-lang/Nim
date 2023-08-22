# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

{.used.}

import unittest, os, strutils
import testscommon
from nimblepkg/common import cd

suite "can handle two binary versions":
  setup:
    cd "binaryPackage/v1":
      check execNimbleYes("install").exitCode == QuitSuccess

    cd "binaryPackage/v2":
      check execNimbleYes("install").exitCode == QuitSuccess

  test "can execute v2":
    let (output, exitCode) = execBin("binaryPackage")
    check exitCode == QuitSuccess
    check output.strip() == "v2"

  test "can update symlink to earlier version after removal":
    check execNimbleYes("remove", "binaryPackage@2.0").exitCode==QuitSuccess

    let (output, exitCode) = execBin("binaryPackage")
    check exitCode == QuitSuccess
    check output.strip() == "v1"

  test "can keep symlink version after earlier version removal":
    check execNimbleYes("remove", "binaryPackage@1.0").exitCode==QuitSuccess

    let (output, exitCode) = execBin("binaryPackage")
    check exitCode == QuitSuccess
    check output.strip() == "v2"
