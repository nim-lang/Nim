discard """
targets: "c js"
"""

import bitops
import std/assertions

proc main() =
  block: # bug #21564
    # tesk `bitops.bitsliced` patch
    doAssert(0x17.bitsliced(4..7) == 0x01)
    doAssert(0x17.bitsliced(0..3) == 0x07)

  block:
    # test in-place `bitops.bitslice`
    var t = 0x12F4
    t.bitslice(4..7)

    doAssert(t == 0xF)

  block:
    # test `bitops.toMask` patch via bitops.masked
    doAssert(0x12FFFF34.masked(8..23) == 0x00FFFF00)

main()

static:
  main()
