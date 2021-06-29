
block: # cmpMem
  type
    SomeHash = array[15, byte]

  var
    a: SomeHash
    b: SomeHash

  a[^1] = byte(1)
  let c = a

  doAssert cmpMem(a.addr, b.addr, sizeof(SomeHash)) > 0
  doAssert cmpMem(b.addr, a.addr, sizeof(SomeHash)) < 0
  doAssert cmpMem(a.addr, c.unsafeAddr, sizeof(SomeHash)) == 0
