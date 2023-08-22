# Package

version       = "0.1.0"
author        = "Dominik Picheta"
description   = "Test package"
license       = "BSD"

# Dependencies

requires "nim >= 0.12.1"

import imp

task testpath, "Testing path":
  impTest()
  let
    cmd = when defined(windows): "cmd /c cd" else: "pwd"
  echo gorgeEx(cmd).output.replace("\\", "/")
  cpFile("imp.nim", "imp2.nim")
  if fileExists("imp2.nim"):
    echo "copied"
  rmFile("imp2.nim")
  if not fileExists("imp2.nim"):
    echo "removed"
