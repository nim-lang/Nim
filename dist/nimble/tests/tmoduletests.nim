# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

{.used.}

import unittest, os, osproc, strutils, testscommon

suite "Module tests":
  template moduleTest(modulePath: string) =
    let moduleName = splitFile(modulePath).name
    test moduleName:
      verify execCmdEx("nim c -r " & modulePath)

  for module in walkDir("../src/nimblepkg"):
    if readFile(module.path).contains("unittest"):
      moduleTest module.path
