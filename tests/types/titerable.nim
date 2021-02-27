discard """
  targets: "c js"
"""

#[
TODO: check UFCS/MCS
]#

# xxx move those to stdlib/ttestutils
template reject(a) =
  doAssert not compiles(a)
template accept(a) =
  doAssert compiles(a)

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
  static: echo typeof(a)
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

# template fn8[T](a: iterable[T]) =

# template fn8a(a: iterable and not typed) = discard
# template fn8b(a: not typed) = discard
# template fn8c(a: itera) = discard

template bad1 =
  template fn4(a: int, b: iterable[float, int]) =
    discard

# iterators
iterator iota(n: int): auto =
  for i in 0..<n: yield i
iterator myiter(n: int): auto =
  for i in 0..<n: yield $(i*2)

iterator iotaClosure(n: int): auto {.closure.} =
  for i in 0..<n: yield i

# template fn(a: int) = discard

template main() =
  #[
  TODO:
  2..4
  ]#
  let expected1 = @[0, 1, 2]
  let expected2 = @["0", "2"]

  doAssert toSeq2(myiter(2)) == expected2
  doAssert toSeq2(iota(3)) == expected1

  when nimvm: discard
  else:
    doAssert toSeq2(iotaClosure(3)) == expected1

  when false:
    # MCS/UFCS doesn't work yet, but maybe will be easier to handle
    discard iota(3).toSeq2()

  doAssert toSeq3(myiter(2)) == expected2
  accept toSeq3(myiter(2))
  reject toSeq3(iota(3))

  doAssert toSeq4(iota(3)) == expected1
  doAssert toSeq4(myiter(2)) == expected2
  # echo toSeq4(2..4)
  # echo toSeq4(13)
  # echo toSeq4(@[2,3,4])

  block:
    accept fn8a(iota(3))
    accept fn7b(iota(3))
    reject fn7c(iota(3))
    reject fn7d(iota(3))
    reject fn7e(iota(3))

  block:
    # PRTEMP
    # fn8(iota(3))
    # fn8b(iota(3))
    fn8a(iota(3))
    # BUG PRTEMP
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

  # doAssert toSeq6(@[@[1]]) == @[2, 3, 4]
  # echo toSeq6(@[@[1]])
  doAssert toSeq6(iota(3)) == expected1
  reject toSeq6(myiter(2))

  reject bad1

static: main()
main()
