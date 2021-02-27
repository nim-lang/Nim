discard """
  targets: "c js"
"""

from stdtest/testutils import accept, reject, whenVMorJs

# toSeq-like templates

template toSeq2(a: iterable): auto =
  var ret: seq[typeof(a)]
  for ai in a: ret.add ai
  ret

template toSeq3(a: iterable[string]): auto =
  var ret: seq[typeof(a)]
  for ai in a: ret.add ai
  ret

template toSeq4[T](a: iterable[T]): auto =
  var ret: seq[typeof(a)]
  for ai in a: ret.add ai
  ret

template toSeq5[T: SomeInteger](a: iterable[T]): auto =
  var ret: seq[typeof(a)]
  for ai in a: ret.add ai
  ret

# template toSeq6(a: iterable[seq]): auto =
template toSeq6(a: iterable[int | float]): auto =
  var ret: seq[typeof(a)]
  for ai in a: ret.add ai
  ret

template fn7b(a: untyped) = discard
template fn7c(a: typed) = discard
template fn7d(a: auto) = discard
template fn7e[T](a: T) = discard

template fn8a(a: iterable) = discard
template fn8b[T](a: iterable[T]) = discard
template fn8c(a: iterable[int]) = discard

template bad1 =
  template fn4(a: int, b: iterable[float, int]) =
    discard

# iterators
iterator iota(n: int): auto =
  for i in 0..<n: yield i

iterator one(T: typedesc): T =
  yield default(T)

iterator myiter(n: int): auto =
  for i in 0..<n: yield $(i*2)

when not defined(js):
  iterator iotaClosure(n: int): auto {.closure.} =
    for i in 0..<n: yield i

template main() =
  #[
  TODO:
  2..4
  ]#
  let expected1 = @[0, 1, 2]
  let expected2 = @["0", "2"]

  doAssert toSeq2(myiter(2)) == expected2
  doAssert toSeq2(iota(3)) == expected1
  doAssert toSeq2(one(float)) == @[0.0]

  whenVMorJs: discard
  do:
    doAssert toSeq2(iotaClosure(3)) == expected1

  when true:
  # when false: # PRTEMP
    # MCS/UFCS
    doAssert iota(3).toSeq2() == expected1

  doAssert toSeq3(myiter(2)) == expected2
  accept toSeq3(myiter(2))
  reject toSeq3(iota(3))

  doAssert toSeq4(iota(3)) == expected1
  doAssert toSeq4(myiter(2)) == expected2
  
  # doAssert toSeq4(0..2) == expected1 # ambig?
  doAssert toSeq4(items(0..2)) == expected1 # ambig?
  doAssert toSeq4(items(@[0,1,2])) == expected1
  reject toSeq4(@[0,1,2])
  reject toSeq4(13)

  block:
    accept fn8a(iota(3))
    accept fn7b(iota(3))
    reject fn7c(iota(3))
    reject fn7d(iota(3))
    reject fn7e(iota(3))

  block:
    fn8a(iota(3))
    reject fn8a(123)
    reject fn8c(123)
    reject fn8c(123.3)
    accept fn8c(items(@[1,2]))

  block:
    # PRTEMP
    # TODO: check w items
    # accept fn7(123)
    discard

  block:
    # shows that iterable is more restrictive than untyped
    reject fn8a(nonexistant)
    accept fn7b(nonexistant)
    reject fn7c(nonexistant)
    reject fn7d(nonexistant)
    reject fn7e(nonexistant)

  doAssert toSeq5(iota(3)) == expected1
  reject toSeq5(myiter(2))

  doAssert toSeq6(iota(3)) == expected1
  reject toSeq6(myiter(2))

  reject bad1

static: main()
main()
