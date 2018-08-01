
block:
  var x = alloc(7)
  assert x != nil
  x = x.realloc(2)
  assert x != nil
  x.dealloc()

block:
  let x = createU(int, 3)
  assert x != nil
  x.dealloc()

block:
  var x = create(int, 4)
  assert x[0] == 0
  assert x[1] == 0
  assert x[2] == 0
  assert x[3] == 0

  x = x.resize(4)
  assert x != nil
  x.dealloc()

block:
  let x = allocShared(100)
  assert x != nil
  deallocShared(x)

block:
  let x = createSharedU(int, 3)
  assert x != nil
  x.deallocShared()

block:
  var x = createShared(int, 3)
  assert x != nil
  assert x[0] == 0
  assert x[1] == 0
  assert x[2] == 0

  x = x.resizeShared(2)
  assert x != nil
  x.deallocShared()

block:
  var x = create(int, 10)
  assert x != nil
  x = x.resize(12)
  assert x != nil
  x.dealloc()

block:
  var x = createShared(int, 1)
  assert x != nil
  x = x.resizeShared(1)
  assert x != nil
  x.deallocShared()

block:
  let x = alloc0(125 shl 23)
  dealloc(x)

block:
  let x = alloc0(126 shl 23)
  dealloc(x)
