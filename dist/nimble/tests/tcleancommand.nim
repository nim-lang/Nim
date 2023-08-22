# Copyright (C) Nimble Authors. All rights reserved.
# BSD License. Look at license.txt for more info.

{.used.}

import unittest, os
import testscommon
from nimblepkg/common import cd

suite "nimble clean":
  test "can clean":
    cd "run":
      check execNimbleYes("build").exitCode == QuitSuccess
      check fileExists("run".addFileExt(ExeExt))

      check execNimbleYes("clean").exitCode == QuitSuccess
      check not fileExists("run".addFileExt(ExeExt))
