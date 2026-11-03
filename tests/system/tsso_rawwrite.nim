discard """
  matrix: "--strings:sso --mm:orc; --mm:orc"
  output: '''
true 0 true true
true
true
'''
"""

# bug #26613: long strings filled through a raw pointer must compare equal
import std/[streams, strutils]

proc fill(want: string): string =
  result = newString(want.len)
  if want.len > 0:
    copyMem(addr result[0], addr want[0], want.len)

var allOk = true
for L in 0..40:
  var want = ""
  for i in 0..<L: want.add char(ord('a') + i mod 26)
  let s = fill(want)
  if s != want or cmp(s, want) != 0 or not (s <= want) or s < want:
    allOk = false
    echo "mismatch at length ", L
  if L > 0 and (not s.startsWith(want[0..0]) or not s.endsWith(want) or
      not want.startsWith(s)):
    allOk = false
    echo "startsWith/endsWith mismatch at length ", L

let want = "abcdefghijklmno"
let s = fill(want)
var p = newString(want.len)
prepareMutation(p)
copyMem(addr p[0], addr want[0], want.len)
echo s == want, " ", cmp(s, want), " ", p == want, " ", allOk

echo newStringStream(want).readAll() == want
var strm = newStringStream("The first line\nthe second line\nthe third line")
echo strm.readAll() == "The first line\nthe second line\nthe third line"
