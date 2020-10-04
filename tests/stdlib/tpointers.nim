import std/pointers

block:
  var a = @[10, 11, 12]
  let pa = a[0].addr
  let pb = pa + 1
  doAssert pb[] == 11
  doAssert (pb - 1)[] == 10
  pa[] = 100
  doAssert a[0] == 100
  doAssert pa[1] == 11

  var pc = pa
  pc += 1
  doAssert pc[] == 11
  doAssert pc[0] == 11
  doAssert pc == pb
  pc -= 1
  doAssert pc == pa
