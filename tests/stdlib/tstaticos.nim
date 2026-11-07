import std/[assertions, staticos, os]

block:
  static:
    doAssert staticDirExists("MISSINGFILE") == false
    doAssert staticFileExists("MISSINGDIR") == false
    doAssert staticDirExists(currentSourcePath().parentDir)
    doAssert staticFileExists(currentSourcePath())

    # bug #24521: checkDir=false (default) must not raise on a missing dir
    var count = 0
    for k, p in walkDir("MISSINGDIR"): count.inc
    doAssert count == 0
