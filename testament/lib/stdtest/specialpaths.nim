#[
todo: move findNimStdLibCompileTime, findNimStdLib here
]#

import os

# Note: all the const paths defined here are known at compile time and valid
# so long Nim repo isn't relocated after compilation.
# This means the binaries they produce will embed hardcoded paths, which
# isn't appropriate for some applications that need to be relocatable.

const sourcePath = currentSourcePath()
  # robust way to derive other paths here
  # We don't depend on PATH so this is robust to having multiple nim
  # binaries

const nimRootDir* = sourcePath.parentDir.parentDir.parentDir.parentDir
  ## root of Nim repo

const stdlibDir* = nimRootDir / "lib"
  # todo: make nimeval.findNimStdLibCompileTime use this

const systemPath* = stdlibDir / "system.nim"

const buildDir* = nimRootDir / "build"
  ## refs #10268: all testament generated files should go here to avoid
  ## polluting .gitignore

static:
  # sanity check
  doAssert fileExists(systemPath)
