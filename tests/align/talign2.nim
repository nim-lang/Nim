block:
  type U = object
    d {.align: 16.}: int8
  var e: seq[ref U]
  for i in 0 ..< 10000: e.add(new U)
  doAssert getTotalMem() <= 1052672 * 2
