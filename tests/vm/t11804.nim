# bug #11804: `x in {a..b}` does not range check `x`, also in the VM
proc fooFunc(c: int): bool =
  result = c in {'a'.ord .. 'z'.ord}

static:
  var c = 194708
  doAssert not fooFunc(c)
  doAssert not fooFunc(-3)
  doAssert fooFunc(98)

doAssert not fooFunc(194708)
doAssert fooFunc(98)
