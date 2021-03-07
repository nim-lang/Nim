discard """
  targets: "c js"
"""

import std/[sequtils,critbits]

template main =
  var r: CritBitTree[void]
  r.incl "abc"
  r.incl "xyz"
  r.incl "def"
  r.incl "definition"
  r.incl "prefix"
  r.incl "foo"

  doAssert r.contains"def"

  r.excl "def"
  doAssert r.missingOrExcl("foo") == false
  doAssert "foo" notin toSeq(r.items)

  doAssert r.missingOrExcl("foo") == true

  doAssert toSeq(r.items) == @["abc", "definition", "prefix", "xyz"]

  doAssert toSeq(r.itemsWithPrefix("de")) == @["definition"]
  var c = CritBitTree[int]()

  c.inc("a")
  doAssert c["a"] == 1

  c.inc("a", 4)
  doAssert c["a"] == 5

  c.inc("a", -5)
  doAssert c["a"] == 0

  c.inc("b", 2)
  doAssert c["b"] == 2

  c.inc("c", 3)
  doAssert c["c"] == 3

  c.inc("a", 1)
  doAssert c["a"] == 1

  var cf = CritBitTree[float]()

  cf.incl("a", 1.0)
  doAssert cf["a"] == 1.0

  cf.incl("b", 2.0)
  doAssert cf["b"] == 2.0

  cf.incl("c", 3.0)
  doAssert cf["c"] == 3.0

  doAssert cf.len == 3
  cf.excl("c")
  doAssert cf.len == 2

  var cb: CritBitTree[string]
  cb.incl("help", "help")
  for k in cb.keysWithPrefix("helpp"):
    doAssert false, "there is no prefix helpp"

  block: # bug #14339
    var strings: CritBitTree[int]
    discard strings.containsOrIncl("foo", 3)
    doAssert strings["foo"] == 3

  block tcritbitsToString:
    block:
      var t: CritBitTree[int]
      t["a"] = 1
      doAssert $t == """{"a": 1}"""
    block:
      var t: CritBitTree[string]
      t["a"] = "1"
      doAssert $t == """{"a": "1"}"""
    block:
      var t: CritBitTree[char]
      t["a"] = '1'
      doAssert $t == """{"a": '1'}"""

main()
static: main()
