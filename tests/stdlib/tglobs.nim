import std/[sugar,globs,os,strutils,sequtils,algorithm]
from std/private/globs as globsOld import nativeToUnixPath
import stdtest/[specialpaths,osutils]

# proc nativeToUnixPath*(path: string): string =
#   # pending https://github.com/nim-lang/Nim/pull/13265
#   doAssert not path.isAbsolute # not implemented here; absolute files need more care for the drive
#   when DirSep == '\\':
#     result = replace(path, '\\', '/')
#   else: result = path

# import timn/exp/taps

proc process[T](a: T): seq[string] =
  a.mapIt(it.path.nativeToUnixPath).sorted

block: # glob
  let dir = buildDir/"D20201013T100140"
  defer: removeDir(dir)
  let paths = """
d1/f1.txt
d1/d1a/f2.txt
d1/d1a/f3
d1/d1a/d1a1/
d1/d1b/d1b1/f4
d2/
f5
""".splitLines.filter(a=>a.len>0)
  genTestPaths(dir, paths)
  doAssert toSeq(glob(dir, follow = a=>a.path.lastPathPart != "d1b", relative = true))
    .filterIt(it.kind == pcFile).process == @["d1/d1a/f2.txt", "d1/d1a/f3", "d1/f1.txt", "f5"]
  doAssert toSeq(glob(dir, relative = true))
    .filterIt(it.kind == pcDir).process == @["d1", "d1/d1a", "d1/d1a/d1a1", "d1/d1b", "d1/d1b/d1b1", "d2"]
  doAssert toSeq(glob(dir, relative = true, includeRoot = true))
    .filterIt(it.kind == pcDir).process == @[".", "d1", "d1/d1a", "d1/d1a/d1a1", "d1/d1b", "d1/d1b/d1b1", "d2"]
  doAssertRaises(OSError): discard toSeq(glob("nonexistant"))
  doAssertRaises(OSError): discard toSeq(glob("f5"))
  doAssert toSeq(glob("nonexistant", checkDir = false)) == @[]
