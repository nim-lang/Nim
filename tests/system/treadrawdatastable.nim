discard """
  matrix: "--mm:refc; --mm:orc; --mm:orc --strings:sso; --backend:cpp --mm:orc; --backend:js --mm:orc"
  output: "OK"
"""

# Tests for `readRawDataStable` and the SSO static-long-string promotion path.
# `readRawDataStable` is available under every string implementation (refc / v2 /
# v3-sso / js) with the same signature, so the code below compiles unchanged on
# all backends -- the point being that users can prepare for `--strings:sso`
# without `when declared` hacks.

import std/assertions

const hasNativeSso = defined(nimsso) and
  (defined(gcArc) or defined(gcAtomicArc) or defined(gcOrc) or defined(gcYrc))

type
  Reader = object
    buf: string
    p: ptr UncheckedArray[char]

proc openFromBuffer(buf: sink string): Reader =
  # `result` (and thus `buf`) is moved into the caller on return. A plain
  # `readRawData` pointer into a small SSO string would dangle after that move;
  # `readRawDataStable` pins the buffer to a stable address first.
  result = Reader(buf: buf)
  result.p = readRawDataStable(result.buf)

proc testStable() =
  when not defined(js):  # raw pointers are a degenerate nil no-op on the JS backend
    block: # short buffer (kept inline under SSO) survives the move
      var r = openFromBuffer("hello")
      doAssert r.buf == "hello"
      doAssert r.p[0] == 'h'
      doAssert r.p[4] == 'o'
      # Stable pointer == the live buffer's raw data after the move.
      doAssert cast[uint](r.p) == cast[uint](readRawData(r.buf))
    block: # medium buffer (len 12: inline overlay under SSO)
      var r = openFromBuffer("hello world!")
      doAssert r.p[11] == '!'
    block: # already-long buffer: returned as-is (already heap-resident)
      var r = openFromBuffer("this is a fairly long string buffer")
      doAssert r.p[0] == 't'
      doAssert r.p[34] == 'r'
    block: # empty string: API is callable (the data pointer is implementation-defined)
      var e = ""
      discard readRawDataStable(e)
  else:
    # On JS the API exists and is callable (returns nil) so call sites are portable.
    var s = "hello"
    discard readRawDataStable(s)

proc testStaticLongPromotion() =
  # Regression for the static-long -> heap promotion: when a string literal
  # longer than the inline payload (PayloadSize = 14 under SSO) is first
  # mutated, the new heap block must be filled from the full static payload,
  # not from the 7-byte inline hot-prefix cache. Reading from the cache copied
  # 7 valid chars and then ran off into the `more` pointer bytes -- the bug that
  # corrupted .nif index files on Windows bootstrap (see Nimony tstatic_long_add).
  # The assertion holds on every backend; only SSO ever risked the corruption.
  var content = "(.nif27)\n(index\n"   # len 16
  let expected = "(.nif27)\n(index\n"
  content.add 'X'                       # triggers static-long -> heap promotion
  doAssert content.len == 17
  doAssert content == expected & "X"
  for i in 0 ..< expected.len:
    doAssert content[i] == expected[i]

when hasNativeSso:
  # A few SSO-tier-boundary sanity checks (short / medium / long, COW, shrink).
  proc testSsoTiers() =
    var a = "(.nif27)\n(index\n"        # static long
    let b = "(.nif27)\n(index\n"
    doAssert a == b
    a.add 'Z'
    doAssert a == "(.nif27)\n(index\nZ"

    var c = "abcdefghijklmnop"          # static long, len 16
    var d = c                            # COW share
    d[0] = 'X'
    doAssert c == "abcdefghijklmnop"     # original untouched
    doAssert d == "Xbcdefghijklmnop"

    var e = "abcdefghijklmnop"
    e.setLen 3                           # shrink below the inline cache size
    doAssert e == "abc"
    doAssert e.len == 3
else:
  proc testSsoTiers() = discard

testStable()
testStaticLongPromotion()
testSsoTiers()
echo "OK"
