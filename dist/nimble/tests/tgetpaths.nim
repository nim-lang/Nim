# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

{.used.}

import unittest, strutils, os
import testscommon
from nimblepkg/common import cd

suite "nimble getPaths/getPathsClause":
  test "check getPaths result":
    cd "tasks/getpaths":
      let (output, exitCode) = execNimble("echoPaths")
      check output.contains("--path:")
      check output.contains("benchy")
      check output.contains("unittest2")
      check exitCode == QuitSuccess
