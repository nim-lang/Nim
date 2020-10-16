import std/[sugar,globs,os,strutils,sequtils,algorithm]
from std/private/osutils as osutils2 import nativeToUnixPath
import stdtest/[specialpaths,osutils]

import timn/exp/taps

proc processAux[T](a: T): seq[string] =
  a.mapIt(it.path.nativeToUnixPath)
proc process[T](a: T): seq[string] =
  a.processAux.sorted

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

  proc mySort(a, b: PathEntrySub): int = cmp(a.path, b.path)
  proc mySort2(a, b: PathEntrySub): int = -cmp(a.path, b.path)
  doAssert toSeq(glob(dir, relative = true, sortCmp = mySort2)).processAux == @["f5", "d2", "d1", "d1/f1.txt", "d1/d1b", "d1/d1a", "d1/d1a/f3", "d1/d1a/f2.txt", "d1/d1a/d1a1", "d1/d1b/d1b1", "d1/d1b/d1b1/f4"]
  doAssert toSeq(glob(dir, relative = true, sortCmp = mySort))
    .processAux.tap == @["d1", "d2", "f5", "d1/d1a", "d1/d1b", "d1/f1.txt", "d1/d1b/d1b1", "d1/d1b/d1b1/f4", "d1/d1a/d1a1", "d1/d1a/f2.txt", "d1/d1a/f3"]
