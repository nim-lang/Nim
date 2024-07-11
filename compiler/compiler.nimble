include "../lib/system/compilation.nim"
version = $NimMajor & "." & $NimMinor & "." & $NimPatch
author = "Andreas Rumpf"
description = "Compiler package providing the compiler sources as a library."
license = "MIT"
skipDirs = @["."]
installDirs = @["compiler"]

import os

var compilerDir = ""

before install:
  rmDir("compiler")

  let
    files = listFiles(".")
    dirs = listDirs(".")

  mkDir("compiler")

  for f in files:
    cpFile(f, "compiler" / f)

  for d in dirs:
    cpDir(d, "compiler" / d)

requires "nim"
