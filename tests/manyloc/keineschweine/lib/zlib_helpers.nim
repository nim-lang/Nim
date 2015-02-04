import zlib

proc compress*(source: string): string =
  var
    sourcelen = source.len
    destlen = sourcelen + (sourcelen.float * 0.1).int + 16
  result = ""
  result.setLen destLen
  var res = zlib.compress(cstring(result), addr destLen, cstring(source), sourceLen)
  if res != Z_OK:
    echo "Error occured: ", res
  elif destLen < result.len:
    result.setLen(destLen)

proc uncompress*(source: string, destLen: var int): string =
  result = ""
  result.setLen destLen
  var res = zlib.uncompress(cstring(result), addr destLen, cstring(source), source.len)
  if res != Z_OK:
    echo "Error occured: ", res


when isMainModule:
  import strutils
  var r = compress("Hello")
  echo repr(r)
  var l = "Hello".len
  var rr = uncompress(r, l)
  echo repr(rr)
  assert rr == "Hello"

  proc `*`(a: string; b: int): string {.inline.} = result = repeatStr(b, a)
  var s = "yo dude sup bruh homie" * 50
  r = compress(s)
  echo s.len, " -> ", r.len

  l = s.len
  rr = uncompress(r, l)
  echo r.len, " -> ", rr.len
  assert rr == s