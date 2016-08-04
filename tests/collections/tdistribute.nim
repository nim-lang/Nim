import sequtils

# distribute tests
let numbers = @[1, 2, 3, 4, 5, 6, 7]
doAssert numbers.distribute(3) == @[@[1, 2, 3], @[4, 5], @[6, 7]]
doAssert numbers.distribute(6)[0] == @[1, 2]
doAssert numbers.distribute(6)[5] == @[7]

let a = @[1, 2, 3, 4, 5, 6, 7]
doAssert a.distribute(1, true)   == @[@[1, 2, 3, 4, 5, 6, 7]]
doAssert a.distribute(1, false)  == @[@[1, 2, 3, 4, 5, 6, 7]]
doAssert a.distribute(2, true)   == @[@[1, 2, 3, 4], @[5, 6, 7]]
doAssert a.distribute(2, false)  == @[@[1, 2, 3, 4], @[5, 6, 7]]
doAssert a.distribute(3, true)   == @[@[1, 2, 3], @[4, 5], @[6, 7]]
doAssert a.distribute(3, false)  == @[@[1, 2, 3], @[4, 5, 6], @[7]]
doAssert a.distribute(4, true)   == @[@[1, 2], @[3, 4], @[5, 6], @[7]]
doAssert a.distribute(4, false)  == @[@[1, 2], @[3, 4], @[5, 6], @[7]]
doAssert a.distribute(5, true)   == @[@[1, 2], @[3, 4], @[5], @[6], @[7]]
doAssert a.distribute(5, false)  == @[@[1, 2], @[3, 4], @[5, 6], @[7], @[]]
doAssert a.distribute(6, true)   == @[@[1, 2], @[3], @[4], @[5], @[6], @[7]]
doAssert a.distribute(6, false)  == @[
  @[1, 2], @[3, 4], @[5, 6], @[7], @[], @[]]
doAssert a.distribute(8, false)  == a.distribute(8, true)
doAssert a.distribute(90, false) == a.distribute(90, true)

var b = @[0]
for f in 1 .. 25: b.add(f)
doAssert b.distribute(5, true)[4].len == 5
doAssert b.distribute(5, false)[4].len == 2
