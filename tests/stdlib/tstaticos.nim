import std/[assertions, staticos, os]

block:
  static:
    doAssert staticDirExists("MISSINGFILE") == false
    doAssert staticFileExists("MISSINGDIR") == false
    doAssert staticDirExists(currentSourcePath().parentDir)
    doAssert staticFileExists(currentSourcePath())
