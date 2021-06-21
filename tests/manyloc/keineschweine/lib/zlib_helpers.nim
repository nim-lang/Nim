# xxx this test is bad (echo instead of error, etc)

import zip/zlib

proc compress*(source: string): string =
  var
    sourcelen = source.len
    destLen = sourcelen + (sourcelen.float * 0.1).int + 16
  result = ""
  result.setLen destLen
  # see http://www.zlib.net/zlib-1.2.11.tar.gz for correct definitions
  var destLen2 = destLen.Ulongf
  var res = zlib.compress(cstring(result), addr destLen2, cstring(source), sourceLen.Ulong)
  if res != Z_OK:
    echo "Error occurred: ", res
  elif destLen2.int < result.len:
    result.setLen(destLen2.int)

proc uncompress*(source: string, destLen: var int): string =
  result = ""
  result.setLen destLen
  var destLen2 = destLen.Ulongf
  var res = zlib.uncompress(cstring(result), addr destLen2, cstring(source), source.len.Ulong)
  if res != Z_OK:
    echo "Error occurred: ", res


when true:
  import strutils
  var r = compress("Hello")
  echo repr(r)
  var ln = "Hello".len
  var rr = uncompress(r, ln)
  echo repr(rr)
  assert rr == "Hello"

  proc `*`(a: string; b: int): string {.inline.} = result = repeat(a, b)
  var s = "yo dude sup bruh homie" * 50
  r = compress(s)
  echo s.len, " -> ", r.len

  ln = s.len
  rr = uncompress(r, ln)
  echo r.len, " -> ", rr.len
  assert rr == s
