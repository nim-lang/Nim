# xxx move to here other tests that belong here; io is a proper module

import std/os
from stdtest/specialpaths import buildDir

block: # readChars
  let file = buildDir / "D20201118T205105.txt"
  let s = "he\0l\0lo"
  writeFile(file, s)
  defer: removeFile(file)
  let f = open(file)
  defer: close(f)
  let n = f.getFileInfo.blockSize
  var buf = newString(n)
  template fn =
    let n2 = f.readChars(buf)
    doAssert n2 == s.len
    doAssert buf[0..<n2] == s
  fn()
  setFilePos(f, 0)
  fn()

  block:
    setFilePos(f, 0)
    var s2: string
    let nSmall = 2
    for ai in buf.mitems: ai = '\0'
    var n2s: seq[int]
    while true:
      let n2 = f.readChars(toOpenArray(buf, 0, nSmall-1))
      # xxx: maybe we could support: toOpenArray(buf, 0..nSmall)
      n2s.add n2
      s2.add buf[0..<n2]
      if n2 == 0:
        break
    doAssert n2s == @[2,2,2,1,0]
    doAssert s2 == s
