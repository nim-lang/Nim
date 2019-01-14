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

const testBuildDir* = nimRootDir / "tests" / "build"
  ## refs #nim-lang/RFCs#119 testament generated files should go in a gitignored
  ## dir to avoid polluting top-level .gitignore. Files that need to be under
  ## tests (eg generated nim files) can go under `testBuildDir` so they'll
  ## have access to tests/nim.cfg. Other generated files can go under `buildDir`.

const buildDir* = nimRootDir / "build"
  ## see also `testBuildDir`

static:
  # sanity check
  doAssert fileExists(systemPath)
