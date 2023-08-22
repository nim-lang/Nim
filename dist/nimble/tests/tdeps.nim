# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

{.used.}

import unittest, os, osproc, strutils, strformat
import testscommon
from nimblepkg/common import cd

suite "nimble deps":
  test "nimble deps":
    cd "deps":
      let (output, exitCode) = execCmdEx(nimblePath & " --silent deps -y")
      check exitCode == QuitSuccess
      check output.contains("""
deps
  timezones 0.5.4(resolved 0.5.4)
    nim >= 0.19.9
""")

  test "nimble deps(json)":
    cd "issue727":
      let (output, exitCode) = execCmdEx(nimblePath & " --format:json deps -y")
      check exitCode == QuitSuccess
      check output.contains("""
[
  {
    "name": "timezones",
    "version": "@any",
    "resolvedTo": "0.5.4",
    "error": "",
    "dependencies": [
      {
        "name": "nim",
        "version": ">= 0.19.9",
        "resolvedTo": "",
        "error": "",
        "dependencies": []
      }
    ]
  }
]
""")
