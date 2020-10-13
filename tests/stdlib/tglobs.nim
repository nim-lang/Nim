import std/[sugar,globs,os,strutils]
import stdtest/specialpaths

block: # glob
  let dir = buildDir/"D20201013T100140"
  defer: removeDir(dir)
  let files = """
d1/f1.txt
d1/d2/f2.txt
d1/d2/f3.txt
d1/d3/
d4/
""".splitLines
  for 

  for a in walkDirRecFilter(".", follow = a=>a.path.lastPathPart notin ["nimcache", ".git", ".csources", "bin"]):
    echo a
