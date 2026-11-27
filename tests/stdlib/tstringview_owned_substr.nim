discard """
  matrix: "--mm:refc; --mm:orc"
  targets: "c cpp js"
"""

import std/assertions

proc checkChars(chars: openArray[char], full: string) =
  doAssert chars.toOwned() == full

  doAssert chars.substr() == full
  doAssert chars.substr(1, 2) == "de"
  doAssert chars.substr(-9, 99) == full
  doAssert chars.substr(9, 99) == ""
  doAssert chars.substr(2, 1) == ""

  doAssert chars.toOwned() == chars.substr()

proc checkBytes(bytes: openArray[byte], full: string) =
  doAssert bytes.toOwned() == full

template main =
  block:
    let s = "abcdefgh"
    checkChars(s.toOpenArray(2, 5), "cdef")
    checkBytes(s.toOpenArrayByte(2, 5), "cdef")
    doAssert s.substr(2, 5) == s.toOpenArray(2, 5).substr()

  block:
    let s = "abc"
    doAssert s.toOpenArray(1, s.high).toOwned() == "bc"
    doAssert s.toOpenArray(1, s.high).substr(-2, 99) == "bc"
    doAssert s.toOpenArray(1, s.high).substr(1) == "c"

static: main()
main()
