import std/[sugar,globs,os,strutils,sequtils,algorithm]
import stdtest/[specialpaths,osutils]

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
""".splitLines.filter(a=>a.len>0)
  genTestPaths(dir, paths)
  doAssert toSeq(glob(dir, follow = a=>a.path.lastPathPart != "d1b", relative = true))
    .filterIt(it.kind == pcFile).mapIt(it.path).sorted == @["d1/d1a/f2.txt", "d1/d1a/f3", "d1/f1.txt"]
  doAssert toSeq(glob(dir, relative = true))
    .filterIt(it.kind == pcDir).mapIt(it.path).sorted == @["d1", "d1/d1a", "d1/d1a/d1a1", "d1/d1b", "d1/d1b/d1b1", "d2"]
  doAssertRaises(OSError): discard toSeq(glob("nonexistant"))
  doAssert toSeq(glob("nonexistant", checkDir = false)) == @[]
