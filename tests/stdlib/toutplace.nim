import std/[outplace, algorithm, random, os]

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
  let c = b.>shuffle() # D20200205T024841:here
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

proc process[T](a: T): T =
  result = a & 0

proc fun(a: var seq[int], b: int) =
  # echo cast[int](a[0].addr)
  a.add b

proc main2() =
  when false:
    mydebug:
      let b = a.>fun(4).>fun(5).>fun(6).process
      echo b
  let b = (@[1,2] & 3).>fun(4).>fun(5).>fun(6).process.process.>fun(7).>fun(8).process.>fun(9)
  doAssert b == @[1, 2, 3, 4, 5, 6, 0, 0, 7, 8, 0, 9]

  var s = newSeqOfCap[int](10)
  s.add 0
  let p1 = s[0].addr
  # discard s.>fun(4).>fun(5).>fun(6) # TODO
  var s2 = s.>fun(4).>fun(5).>fun(6)
  let p2 = s2[0].addr
  doAssert s2 == @[0, 4, 5, 6]
  # doAssert p1 == p2 # false

  # 2 chains interrupted in middle
  let b3 = @[1].>fun(2).>fun(3).process.process.>fun(4).>fun(5).process.>fun(6)
  doAssert b3 == @[1, 2, 3, 0, 0, 4, 5, 0, 6]

main()
main2()
