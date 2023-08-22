discard """
  targets: "c js"
"""


block divUint64:
  proc divTest() =
    let x1 = 12'u16
    let y = x1 div 5'u16
    let x2 = 1345567'u32
    let z = x2 div 5'u32
    let a = 1345567'u64 div uint64(x1)
    doAssert y == 2
    doAssert z == 269113
    doAssert a == 112130

  static: divTest()
  divTest()

