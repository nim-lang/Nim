discard """
  matrix: "--mm:refc; --mm:orc"
"""

import std/os
import std/assertions

when doslikeFileSystem:
  import std/pathnorm

  template initVars =
    var state {.inject.} = 0
    var result {.inject.}: string

  block: # / -> /
    initVars
    addNormalizePath("//?/c:/./foo//bar/../baz", result, state, '/')
    doAssert result == "//?/c:/foo/baz"
    addNormalizePath("me", result, state, '/')
    doAssert result == "//?/c:/foo/baz/me"

  block: # / -> \
    initVars
    addNormalizePath(r"//?/c:/./foo//bar/../baz", result, state, '\\')
    doAssert result == r"\\?\c:\foo\baz"
    addNormalizePath("me", result, state, '\\')
    doAssert result == r"\\?\c:\foo\baz\me"

  block: # Append path component to UNC drive
    initVars
    addNormalizePath(r"//?/c:", result, state, '\\')
    doAssert result == r"\\?\c:"
    addNormalizePath("Users", result, state, '\\')
    doAssert result == r"\\?\c:\Users"
    addNormalizePath("me", result, state, '\\')
    doAssert result == r"\\?\c:\Users\me"
