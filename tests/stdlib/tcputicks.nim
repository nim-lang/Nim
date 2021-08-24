discard """
  targets: "c cpp js"
  matrix: "; -d:danger"
"""

import std/cputicks

template main =
  let n = 100
  for i in 0..<n:
    let t1 = getCpuTicks()
    let t2 = getCpuTicks()
    doAssert t2 > t1

  for i in 0..<100:
    let t1 = getCpuTicksStart()
    # code to benchmark can go here
    let t2 = getCpuTicksEnd()
    doAssert t2 > t1

static: main()
main()
