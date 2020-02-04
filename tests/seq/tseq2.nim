proc main() =
  var a = @[10,11]
  a.add 12
  doAssert $a == "@[10, 11, 12]"
  doAssert type(a) is seq[int]
  doAssert type(a) is seq
  var a2 = default(type(a))
  for ai in a:
    a2.add ai*10
  doAssert a2 == @[100, 110, 120]
  var a3 = newSeq[int](1)
  doAssert a3 == @[0]
  a3.add 17
  a3.newSeq(4)
  doAssert a3 == @[0, 17, 0, 0]
  var a4 = @["foo"] & @["bar"]
  a4[0] = "FOO"
  a4[1].add "t"
  doAssert a4 == @["FOO", "bart"]
  a4 = @[]
  doAssert a4.len == 0

main()
