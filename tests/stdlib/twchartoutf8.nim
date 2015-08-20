#assume WideCharToMultiByte always produce correct result
#windows only

when not defined(windows):
  {.error: "windows only".}
  
{.push gcsafe.}

const CP_UTF8 = 65001'i32

type
  LPBOOL = ptr int32
  LPWCSTR = ptr uint16
  
proc WideCharToMultiByte*(CodePage: int32, dwFlags: int32,
                          lpWideCharStr: LPWCSTR, cchWideChar: int32,
                          lpMultiByteStr: cstring, cchMultiByte: int32,
                          lpDefaultChar: cstring, lpUsedDefaultChar: LPBOOL): int32{.
    stdcall, dynlib: "kernel32", importc: "WideCharToMultiByte".}

{.pop.}

proc convertToUTF8(wc: WideCString, wclen: int32): string =
  let size = WideCharToMultiByte(CP_UTF8, 0'i32, cast[LPWCSTR](addr(wc[0])), wclen, 
    cstring(nil), 0'i32, cstring(nil), LPBOOL(nil))
  result = newString(size)
  let res = WideCharToMultiByte(CP_UTF8, 0'i32, cast[LPWCSTR](addr(wc[0])), wclen, 
    cstring(result), size, cstring(nil), LPBOOL(nil))
  result[size] = chr(0)
  assert size == res
   
proc testCP(wc: WideCString, lo, hi: int) =
  var x = 0
  let chunk = 1024
  for i in lo..hi:
    wc[x] = cast[TUtf16Char](i)
    if (x >= chunk) or (i >= hi):
      wc[x] = TUtf16Char(0)
      var a = convertToUTF8(wc, int32(x))
      var b = wc $ chunk
      assert a == b
      x = 0
    inc x

proc testCP2(wc: WideCString, lo, hi: int) =
  assert ((lo >=0x10000) and (hi <= 0x10FFFF))
  var x = 0
  let chunk = 1024
  for i in lo..hi:
    let ch = i - 0x10000
    let W1 = 0xD800 or (ch shr 10)
    let W2 = 0xDC00 or (0x3FF and ch)
    wc[x] = cast[TUtf16Char](W1)
    wc[x+1] = cast[TUtf16Char](W2)
    inc(x, 2)
    
    if (x >= chunk) or (i >= hi):
      wc[x] = TUtf16Char(0)
      var a = convertToUTF8(wc, int32(x))
      var b = wc $ chunk
      assert a == b
      x = 0

#RFC-2781 "UTF-16, an encoding of ISO 10646"

var wc: WideCString
unsafeNew(wc, 1024 * 4 + 2)

#U+0000 to U+D7FF
#skip the U+0000
wc.testCP(1, 0xD7FF)

#U+E000 to U+FFFF
wc.testCP(0xE000, 0xFFFF)

#U+10000 to U+10FFFF
wc.testCP2(0x10000, 0x10FFFF)
echo "OK"