import std/mersenne

template main() =
  var mt = newMersenneTwister(2525)

  doAssert mt.getNum == 407788156'u32
  doAssert mt.getNum == 1071751096'u32
  doAssert mt.getNum == 3805347140'u32


static: main()
main()
