import sequtils, critbits


var r: CritBitTree[void]
r.incl "abc"
r.incl "xyz"
r.incl "def"
r.incl "definition"
r.incl "prefix"
r.incl "foo"

doAssert r.contains"def"

r.excl "def"
assert r.missingOrExcl("foo") == false
assert "foo" notin toSeq(r.items)

assert r.missingOrExcl("foo") == true

assert toSeq(r.items) == @["abc", "definition", "prefix", "xyz"]

assert toSeq(r.itemsWithPrefix("de")) == @["definition"]
var c = CritBitTree[int]()

c.inc("a")
assert c["a"] == 1

c.inc("a", 4)
assert c["a"] == 5

c.inc("a", -5)
assert c["a"] == 0

c.inc("b", 2)
assert c["b"] == 2

c.inc("c", 3)
assert c["c"] == 3

c.inc("a", 1)
assert c["a"] == 1

var cf = CritBitTree[float]()

cf.incl("a", 1.0)
assert cf["a"] == 1.0

cf.incl("b", 2.0)
assert cf["b"] == 2.0

cf.incl("c", 3.0)
assert cf["c"] == 3.0

assert cf.len == 3
cf.excl("c")
assert cf.len == 2

var cb: CritBitTree[string]
cb.incl("help", "help")
for k in cb.keysWithPrefix("helpp"):
  doAssert false, "there is no prefix helpp"
