
type
  AObj = object
    i: int
    d: float
  ATup = tuple
    i: int
    d: float
  MyEnum = enum
    E01, E02, E03
  Myrange = range[0..10]

  MyProc = proc (x: int): bool
  MyInt = distinct int
  MyAlias = MyInt
  MySet = set[char]
  MyArray = array[4, char]
  MySeq = seq[string]

template test(typename, default: untyped) =
  proc `abc typename`(): seq[typename] =
    result = newSeq[typename]()
    result.add(default)
    result.setLen(3)
    for i in 0 ..< 2:
      result[i] = default

  const constval = `abc typename`()
  doAssert(constval == `abc typename`())

  proc `arr typename`(): array[4, typename] =
    for i in 0 ..< 2:
      result[i] = default
  const constarr = `arr typename`()
  doAssert(constarr == `arr typename`())

proc even(x: int): bool = x mod 2 == 0
proc `==`(x, y: MyInt): bool = ord(x) == ord(y)
proc `$`(x: MyInt): string = $ord(x)
proc `$`(x: proc): string =
  if x.isNil: "(nil)" else: "funcptr"

test(int, 0)
test(uint, 0)
test(float, 0.1)
test(char, '0')
test(bool, false)
test(uint8, 2)
test(string, "data")
test(MyProc, even)
test(MyEnum, E02)
test(AObj, AObj())
test(ATup, (i:11, d:9.99))
test(Myrange, 4)
test(MyInt, MyInt(4))
test(MyAlias, MyAlias(4))
test(MyArray, ['0','1','2','3'])
test(MySeq, @["data"])
