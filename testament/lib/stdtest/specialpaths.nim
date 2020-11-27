#[
todo: move findNimStdLibCompileTime, findNimStdLib here
xxx: consider moving this to $nim/compiler/relpaths.nim to get relocatable paths

## note: $lib vs $nim
note: these can resolve to 3 different paths if running via `nim c --lib:lib foo`,
eg if compiler was installed via nimble (or is in nim path), and nim is external
(ie not in `$lib/../bin/` dir)

import "$lib/../compiler/nimpaths" # <- most robust if you want to favor --lib:lib
import "$nim/compiler/nimpaths"
import compiler/nimpaths
]#

import os

# Note: all the const paths defined here are known at compile time and valid
# so long Nim repo isn't relocated after compilation.
# This means the binaries they produce will embed hardcoded paths, which
# isn't appropriate for some applications that need to be relocatable.

const
  sourcePath = currentSourcePath()
    # robust way to derive other paths here
    # We don't depend on PATH so this is robust to having multiple nim binaries
  nimRootDir* = sourcePath.parentDir.parentDir.parentDir.parentDir ## root of Nim repo
  stdlibDir* = nimRootDir / "lib"
  systemPath* = stdlibDir / "system.nim"
  testsDir* = nimRootDir / "tests"
  buildDir* = nimRootDir / "build"
    ## refs #10268: all testament generated files should go here to avoid
    ## polluting .gitignore

static:
  # sanity check
  doAssert fileExists(systemPath)
