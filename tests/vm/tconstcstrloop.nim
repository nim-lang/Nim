discard """
  timeout: 10
  joinable: false
"""

# Regression: a `const` array of `cstring` filled in a compile-time loop used to
# get EVERY element set to the last value, because `opcStrToCStr` returned a
# pointer into the VM string's reusable payload instead of stable memory.
# Works on 2.2.12, broken on 2.4.0 (both the C and the JS backend).

type Kind = enum
  a = "aa", b = "bb", c = "cc", d = "dd", e = "ee", f = "ff"

let expected: array[Kind, cstring] = ["aa", "bb", "cc", "dd", "ee", "ff"]

const tags = block:
  var r: array[Kind, cstring]
  for k in Kind: r[k] = $k
  r

doAssert tags == expected,
  "const array[cstring] filled in a CT loop: " & $tags

# the same with an explicit conversion:
const tags2 = block:
  var r: array[Kind, cstring]
  for k in Kind: r[k] = cstring($k)
  r

doAssert tags2 == expected,
  "const array[cstring] with explicit cstring(): " & $tags2

# plain string arrays must keep working:
const tags3 = block:
  var r: array[Kind, string]
  for k in Kind: r[k] = $k
  r

doAssert tags3 == ["aa", "bb", "cc", "dd", "ee", "ff"],
  "const array[string] filled in a CT loop: " & $tags3

# and a runtime array must be unaffected:
let rt = block:
  var r: array[Kind, cstring]
  for k in Kind: r[k] = $k
  r

doAssert rt == expected,
  "runtime array[cstring]: " & $rt

# stress: a big compile-time loop, one conversion per iteration -- with a
# per-conversion copy this would grow the const arena without bound, with the
# StrlitFlag pin it must stay correct and cheap:
const many = block:
  var r: array[2048, cstring]
  for i in 0..<2048: r[i] = $i
  r

doAssert many[0] == "0" and many[2047] == "2047",
  "big CT loop array[cstring]: " & $many[0] & " " & $many[2047]
