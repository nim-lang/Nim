discard """
  targets: "c js"
"""

import std/paths

block: # isPortableFilename
  doAssert isPortableFilename("abc", maxLen = 3)
  doAssert not isPortableFilename("abcd", maxLen = 3)
  for a in ["con", "aux", "prn", "OwO|UwU", " foo", "foo ", "foo.", "con.txt", "aux.bat", "prn.exe", "nim>.nim", " foo.log"]:
    doAssert not isPortableFilename(a), a
  for a in ["c0n", "foo.aux", "bar.prn", "OwO_UwU", "cron", "ux.bat", "nim.nim", "foo.log", "foo.bar.baz", "foo bar .baz"]:
    doAssert isPortableFilename(a), a
