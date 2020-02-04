import std/[outplaces, algorithm, random, os]

proc main() =
  var a = @[1, 2, 3, 4, 5, 6, 7, 8, 9]
  doAssert a.>sort() == sorted(a)
  #Chaining:
  var aCopy = a
  aCopy.insert(10)
  doAssert a.>insert(10).>sort() == sorted(aCopy)
  doAssert @[1,3,2].>sort().>sort(order = SortOrder.Descending) == @[3,2,1]
    # using 2 `.>` chained together

  proc bar(x: int, ret: var int) = ret += x
  doAssert 3.>bar(4, _) == 3 + 4

  const b = @[0, 1, 2]
  let c = b.>shuffle()
  doAssert c[0] == 1
  doAssert c[1] == 0

  block:
    var a = "foo"
    var b = "bar"
    doAssert "ab".>add("cd") == "abcd"
    let ret = "ab".>add "cd" # example with `nnkCommand`
    doAssert ret == "abcd"

  when defined(posix):
    doAssert "foo./bar///".>normalizePathEnd() == "foo./bar"

main()
