import std/[decimal, strutils]

template assertEquals*(actual, expected: untyped): untyped =
  doAssert actual == expected,
    "\n" &
    "     Got: " & $(actual) & "\n" &
    "Expected: " & $(expected) & "\n"

template assertEquals*(testNo, actual, expected: untyped): untyped =
  doAssert actual == expected,
    "\n" &
    "    Test: " & testNo & "\n" &
    "     Got: " & $(actual) & "\n" &
    "Expected: " & $(expected) & "\n"

proc conversionTest*(testNo: int, hexStr: string, canonicalStr: string, lossy: bool, nonCanonicalStrs: seq[string]) =
  let upperHexStr = hexStr.toUpperAscii
  let decoded = hexStr.decodeHex()
  let s = $decoded
  let test = $testNo
  assertEquals(test & " decode", s, canonicalStr)
  
  let parsed = newDecimal(canonicalStr)
  assertEquals(test & " parse canonical (" & canonicalStr & ")", parsed.toHex, upperHexStr)
  #
  var ctr = 0
  for nonCanonStr in nonCanonicalStrs:
    let ncParsed = newDecimal(nonCanonStr)
    assertEquals(test & " parse noncanonical " & $ctr, ncParsed.toHex, upperHexStr)
    ctr += 1
  echo "    test $1: $2 and $3 ... all good!".format(testNo, canonicalStr, hexStr)

