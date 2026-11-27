discard """
  matrix: "--mm:refc; --mm:orc"
"""

# bug #26421: overlong UTF-8 sequences must not decode to ASCII or NUL

import std/[widestrs, assertions]

doAssert $newWideCString("a\xE0\x80\xAFb") == "a�b"
doAssert $newWideCString("abc\xE0\x80\x80def") == "abc�def"
doAssert $newWideCString("a\xC0\xAFb") == "a�b"
doAssert $newWideCString("a\xF0\x80\x80\xAFb") == "a�b"
# shortest forms still decode
doAssert $newWideCString("\xC2\x80\xE0\xA0\x80\xF0\x90\x80\x80") == "\u0080ࠀ\u{10000}"
doAssert $newWideCString("äöü€😀") == "äöü€😀"
