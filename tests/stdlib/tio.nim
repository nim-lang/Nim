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


import std/strutils

block: # bug #21273
  let FILE = buildDir / "D20220119T134305.txt"

  let hex = "313632313920313632343720313632353920313632363020313632393020323035363520323037323120323131353020323239393820323331303520323332313020323332343820323332363820"


  writeFile FILE, parseHexStr(hex)

  doAssert readFile(FILE).toHex == hex

  let f = open(FILE)
  var s = newString(80)
  while f.readLine(s):
    doAssert s.toHex == hex
