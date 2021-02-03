discard """
  cmd: "nim $target --os:windows --compileonly $file"
  action: compile
  disabled: windows # so that test runs on posix host but windows target
"""

#[
Tests for cross compilation.
]#

# xxx add a way to test this at RT to make sure windows semantics are used.

import os, strutils

proc main() =
  block:
    const dir = "foo" / "bar"
    static: doAssert dir == "foo/bar"

  block: # bug #16702
    doAssert not defined(posix)
    doAssert defined(windows)
    doAssert "foo" / "bar" == "foo/bar"
    const s = currentSourcePath
    doAssert '\\' notin s
    doAssert '/' in s
    doAssert DirSep == '/'
    let s2 = currentSourcePath
    doAssert s2 == s
    let s3 = s2.parentDir / "baz"
    doAssert s3.endsWith "tests/misc/baz"
    doAssert s3.isAbsolute

static: main()
main()
  # the doAsserts inside here would need to be adjusted, this is just used
  # to make sure it compiles without `static`
