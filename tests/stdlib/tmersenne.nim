import std/mersenne

template main() =
  var mt = newMersenneTwister(2525)

  doAssert mt.getNum == 407788156'u32
  doAssert mt.getNum == 1071751096'u32
  doAssert mt.getNum == 3805347140'u32
  doAssert sample(mt, @[30, 20, 10]) == 20
  doAssert sample(mt, @[30.4, 20.54, 10.5]) == 10.5
  doAssert sample(mt, @['a', 'b', 'c']) == 'b'
  doAssert sample(mt, @["abc", "def", "ghi"]) == "def"
  



static: main()
main()
