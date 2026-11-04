discard """
  matrix: "--strings:sso --mm:orc; --mm:orc; --mm:refc"
  output: "true"
"""

# bug #26613: stdlib procs that fill long strings via raw pointers must
# sync the inline prefix of `--strings:sso` (beginStore/endStore)
import std/[streams, json, os]

var ok = true
template check(cond: bool) =
  if not cond:
    ok = false
    echo "failed: ", astToStr(cond)

for L in [0, 1, 7, 8, 14, 15, 16, 30, 5000]:
  var want = ""
  for i in 0..<L: want.add char(ord('a') + i mod 26)

  check newStringStream(want).readAll() == want
  check newStringStream(want).readStr(L) == want
  check newStringStream(want).peekStr(L) == want
  var s = "xyz"
  newStringStream(want).readStr(L, s)
  check s == want

  var t = ""
  if L > 0:
    copyMem(beginStore(t, L), readRawData(want), L)
    endStore(t)
  check t == want
  check cmp(t, want) == 0

let strm = newStringStream("The first line\nthe second line\nthe third line")
check strm.readAll() == "The first line\nthe second line\nthe third line"
check parseJson(newStringStream("""{"key": "a long string value"}""").readAll())["key"].getStr == "a long string value"

let f = getTempDir() / ("tsso_rawwrite_" & $getCurrentProcessId() & ".txt")
writeFile(f, "a file with more than fifteen chars")
let fs = newFileStream(f)
check fs.readAll() == "a file with more than fifteen chars"
fs.close()
removeFile(f)

echo ok
