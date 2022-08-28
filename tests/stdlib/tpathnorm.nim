discard """
"""

import std/os

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
    addNormalizePath("//?/c:/./foo//bar/../baz", result, state, '\\')
    doAssert result == "\\\\?\\c:\\foo\\baz"
    addNormalizePath("me", result, state, '\\')
    doAssert result == "\\\\?\\c:\\foo\\baz\\me"

  block: # Append path component to UNC drive
    initVars
    addNormalizePath("//?/c:", result, state, '\\')
    doAssert result == "\\\\?\\c:"
    addNormalizePath("Users", result, state, '\\')
    doAssert result == "\\\\?\\c:\\Users"
    addNormalizePath("me", result, state, '\\')
    doAssert result == "\\\\?\\c:\\Users\\me"
