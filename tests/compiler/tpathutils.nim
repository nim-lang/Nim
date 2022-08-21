import compiler/pathutils
import os, strutils


doAssert AbsoluteDir"/Users/me///" / RelativeFile"z.nim" == AbsoluteFile"/Users/me/z.nim"
doAssert AbsoluteDir"/Users/me" / RelativeFile"../z.nim" == AbsoluteFile"/Users/z.nim"
doAssert AbsoluteDir"/Users/me/" / RelativeFile"../z.nim" == AbsoluteFile"/Users/z.nim"
doAssert relativePath("/foo/bar.nim", "/foo/", '/') == "bar.nim"
doAssert $RelativeDir"foo/bar" == "foo/bar"
doAssert RelativeDir"foo/bar" == RelativeDir"foo/bar"
doAssert RelativeFile"foo/bar".changeFileExt(".txt") == RelativeFile"foo/bar.txt"
doAssert RelativeFile"foo/bar".addFileExt(".txt") == RelativeFile"foo/bar.txt"
doAssert not RelativeDir"foo/bar".isEmpty
doAssert RelativeDir"".isEmpty

when defined(windows):
  let nasty = string(AbsoluteDir(r"C:\Users\rumpf\projects\nim\tests\nimble\nimbleDir\linkedPkgs\pkgB-#head\../../simplePkgs/pkgB-#head/") / RelativeFile"pkgA/module.nim")
  doAssert nasty.replace('/', '\\') == r"C:\Users\rumpf\projects\nim\tests\nimble\nimbleDir\simplePkgs\pkgB-#head\pkgA\module.nim"
