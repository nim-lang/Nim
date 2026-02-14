import std/hashes

proc outer() =
  var a = 0
  proc inner() = a.inc
  doAssert inner is "closure"
  let inner2 = inner
  echo "hash(inner):  ", hash(inner)
  echo "hash(inner2): ", hash(inner2)
  doAssert hash(inner2) == hash(inner), "FAIL: hashes don't match!"
  echo "PASS: hashes match"

proc main() =
  outer()

main()
