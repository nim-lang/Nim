discard """
  output: '''
A
A
25.0
210.0
apr
'''
"""


block t4435:
  type
    A[T] = distinct T
    B[T] = distinct T

  proc foo[T](x:A[T]) = echo "A"
  proc foo[T](x:B[T]) = echo "B"
  proc bar(x:A) = echo "A"
  proc bar(x:B) = echo "B"

  var
    a:A[int]

  foo(a) # fine
  bar(a) # testdistinct.nim(14, 4) Error: ambiguous call; both testdistinct.bar(x: A) and testdistinct.bar(x: B) match for: (A[system.int])



block t7010:
  type MyInt = distinct int

  proc `+`(x: MyInt, y: MyInt): MyInt {.borrow.}
  proc `+=`(x: var MyInt, y: MyInt) {.borrow.}
  proc `=`(x: var MyInt, y: MyInt) {.borrow.}

  var next: MyInt

  proc getNext() : MyInt =
      result = next
      next += 1.MyInt
      next = next + 1.MyInt



block t9079:
  type
    Dollars = distinct float

  proc `$`(d: Dollars): string {.borrow.}
  proc `*`(a, b: Dollars): Dollars {.borrow.}
  proc `+`(a, b: Dollars): Dollars {.borrow.}

  var a = Dollars(20)
  a = Dollars(25.0)
  echo a
  a = 10.Dollars * (20.Dollars + 1.Dollars)
  echo a



block t9322:
  type Fix = distinct string
  proc `$`(f: Fix): string {.borrow.}
  proc mystr(s: string) =
    echo s
  mystr($Fix("apr"))


block: # bug #13517
  type MyUint64 = distinct uint64

  proc `==`(a: MyUint64, b: uint64): bool = uint64(a) == b

  block:
    doAssert MyUint64.high is MyUint64
    doAssert MyUint64.high == 18446744073709551615'u64

  static:
    doAssert MyUint64.high is MyUint64
    doAssert MyUint64.high == 18446744073709551615'u64
