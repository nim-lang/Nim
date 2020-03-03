discard """
  output: '''OK'''
"""

#assume WideCharToMultiByte always produce correct result
#windows only

when not defined(windows):
  echo "OK"
else:
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
    doAssert size == res

  proc testCP(wc: WideCString, lo, hi: int) =
    var x = 0
    let chunk = 1024
    for i in lo..hi:
      wc[x] = cast[Utf16Char](i)
      if (x >= chunk) or (i >= hi):
        wc[x] = Utf16Char(0)
        var a = convertToUTF8(wc, int32(x))
        var b = wc $ chunk
        doAssert a == b
        x = 0
      inc x

  proc testCP2(wc: WideCString, lo, hi: int) =
    doAssert((lo >= 0x10000) and (hi <= 0x10FFFF))
    var x = 0
    let chunk = 1024
    for i in lo..hi:
      let ch = i - 0x10000
      let W1 = 0xD800 or (ch shr 10)
      let W2 = 0xDC00 or (0x3FF and ch)
      wc[x] = cast[Utf16Char](W1)
      wc[x+1] = cast[Utf16Char](W2)
      inc(x, 2)

      if (x >= chunk) or (i >= hi):
        wc[x] = Utf16Char(0)
        var a = convertToUTF8(wc, int32(x))
        var b = wc $ chunk
        doAssert a == b
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

  #invalid UTF-16
  const
    b = "\xEF\xBF\xBD"
    c = "\xEF\xBF\xBF"

  wc[0] = cast[Utf16Char](0xDC00)
  wc[1] = Utf16Char(0)
  var a = $wc
  doAssert a == b

  wc[0] = cast[Utf16Char](0xFFFF)
  wc[1] = cast[Utf16Char](0xDC00)
  wc[2] = Utf16Char(0)
  a = $wc
  doAssert a == c & b

  wc[0] = cast[Utf16Char](0xD800)
  wc[1] = Utf16Char(0)
  a = $wc
  doAssert a == b

  wc[0] = cast[Utf16Char](0xD800)
  wc[1] = cast[Utf16Char](0xFFFF)
  wc[2] = Utf16Char(0)
  a = $wc
  doAssert a == b & c

  echo "OK"
