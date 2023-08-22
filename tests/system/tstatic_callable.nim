# bug #16987

proc getNum(a: int): int = a

# Below calls "doAssert getNum(123) == 123" at compile time.
static:
  doAssert getNum(123) == 123

# Below calls evaluate the "getNum(123)" at compile time, but the
# results of those calls get used at run time.
doAssert (static getNum(123)) == 123
doAssert (static(getNum(123))) == 123
