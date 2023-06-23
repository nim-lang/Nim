discard """
  output: '''
Version 2 was called.
This has the highest precedence.
This has the second-highest precedence.
This has the lowest precedence.
baseobj ==
true
even better! ==
true
done extraI=0
test 0 complete, loops=0
done extraI=1
test 1.0 complete, loops=1
done extraI=0
done extraI passed 0
test no extra complete, loops=2
1
'''
"""

# issue 4675
import importA  # comment this out to make it work
import importB
block:
  var x: Foo[float]
  var y: Foo[float]
  let r = t1(x) + t2(y)


block:  # bug #4475
  # Bug: https://github.com/nim-lang/Nim/issues/4475
  # Fix: https://github.com/nim-lang/Nim/pull/4477
  proc test(x: varargs[string], y: int) = discard
  test(y = 1)


block:  # bug #2220
  when true:
    type A[T] = object
    type B = A[int]

    proc q[X](x: X) =
      echo "Version 1 was called."

    proc q(x: B) =
      echo "Version 2 was called."

    q(B()) # This call reported as ambiguous.


block:  # bug #2219
  template testPred(a: untyped) =
    block:
      type A = object of RootObj
      type B = object of A
      type SomeA = A|A # A hack to make "A" a typeclass.

      when a >= 3:
        proc p[X: A](x: X) =
          echo "This has the highest precedence."
      when a == 2:
        proc p[X: SomeA](x: X) =
          echo "This has the second-highest precedence."
      when a >= 1:
        proc p[X](x: X) =
          echo "This has the lowest precedence."

      p(B())

  testPred(3)
  testPred(2)
  testPred(1)


# bug #6526
type
  BaseObj = ref object of RootObj
  DerivedObj = ref object of BaseObj
  OtherDerivate = ref object of BaseObj

proc `==`*[T1, T2: BaseObj](a: T1, b: T2): bool =
  echo "baseobj =="
  return true

let a = DerivedObj()
let b = DerivedObj()
echo a == b

proc `==`*[T1, T2: OtherDerivate](a: T1, b: T2): bool =
  echo "even better! =="
  return true

let a2 = OtherDerivate()
let b2 = OtherDerivate()
echo a2 == b2


import math
block:  # bug #2481
  template test(loopCount: int, extraI: int, testBody: untyped): typed =
    block:
      for i in 0..loopCount-1:
        testBody
      echo "done extraI=", extraI

  template test(loopCount: int, extraF: float, testBody: untyped): typed =
    block:
      test(loopCount, round(extraF).int, testBody)

  template test(loopCount: int, testBody: untyped): typed =
    block:
      test(loopCount, 0, testBody)
      echo "done extraI passed 0"

  var
    loops = 0

  test 0, 0:
    loops += 1
  echo "test 0 complete, loops=", loops

  test 1, 1.0:
    loops += 1
  echo "test 1.0 complete, loops=", loops

  when true:
    # when true we get the following compile time error:
    #   b.nim(35, 6) Error: expression 'loops += 1' has no type (or is ambiguous)
    loops = 0
    test 2:
      loops += 1
    echo "test no extra complete, loops=", loops

block:  # bug #2229
  type
    Type1 = object
      id: int
    Type2 = object
      id: int

  proc init(self: var Type1, a: int, b: ref Type2) =
    echo "1"

  proc init(self: var Type2, a: int) =
    echo """
      Works when this proc commented out
      Otherwise error:
      test.nim(14, 4) Error: ambiguous call; both test.init(self: var Type1, a: int, b: ref Type2) and test.init(self: var Type1, a: int, b: ref Type2) match for: (Type1, int literal(1), ref Type2)
    """

  var aa: Type1
  init(aa, 1, (
      var bb = new(Type2);
      bb
  ))


block:  # bug #4545
  type
    SomeObject = object
      a: int
    AbstractObject = object
      objet: ptr SomeObject

  proc convert(this: var SomeObject): AbstractObject =
    AbstractObject(objet: this.addr)

  proc varargProc(args: varargs[AbstractObject, convert]): int =
    for arg in args:
      result += arg.objet.a

  var obj = SomeObject(a: 17)
  discard varargProc(obj)


# bug #11239
type MySeq*[T] = object

proc foo(a: seq[int]): string = "foo: seq[int]"
proc foo[T](a: seq[T]): string = "foo: seq[T]"
proc foo(a: MySeq[int]): string = "foo: MySeq[int]"
proc foo[T](a: MySeq[T]): string = "foo: MySeq[T]"

doAssert foo(@[1,2,3]) == "foo: seq[int]"
doAssert foo(@["WER"]) == "foo: seq[T]"
doAssert foo(MySeq[int]()) == "foo: MySeq[int]"
doAssert foo(MySeq[string]()) == "foo: MySeq[T]"


block: # issue #22142
  type
    A[T] = object of RootObj
    B[T] = object
    C = object
      x:int
      
  # change (previously true)
  block:
    proc test[J;H: A[J];T: B[H]](param: T): bool = false
    proc test[T](param: B[T]): bool = true
    doAssert test(B[A[int]]()) == false
  
  # change (previously ambiguous)
  block:  
    proc test[T: A](param: T): bool = false
    proc test[T: object](param: T): bool = true
    doAssert test(A[int]()) == false
  block:
    proc test[T: A](param: T): bool = false
    proc test(param: object): bool = true
    doAssert test(A[int]()) == false
  block:
    proc test[H;T: A[H]](param: T): bool = false
    proc test(param: object): bool = true
    doAssert test(A[C]()) == false
  block:
    proc test[H;T: A[B[H]]](param: T): bool = false
    proc test[T: object](param: T): bool = true
    doAssert test(A[B[int]]()) == false
  block:
    #[
    This was referenced in the nim compiler source (`sumGeneric`) as a case
    that was supposed to not be ambiguous, yet it was
    ]#
    proc test[J;H:A[J]; T: A[H]](param: T): bool = false
    proc test[H;T: A[H]](param: T): bool = true
    discard test(A[A[C]]())
  
  # anti-regression
  # exact match
  block:
    proc test[T: A[int]](param: T): bool = false
    proc test(param: A[int]): bool = true
    doAssert test(A[int]()) == true
  block:
    proc test[T: C](param: T): bool = false
    proc test(param: C): bool = true
    doAssert test(C()) == true
  block:
    proc test[T: A[B[C]]](param: T): bool = false
    proc test(param: A[B[C]]): bool = true
    doAssert test(A[B[C]]()) == true
  block:
    proc test[T: A[int]](param: T): bool = false
    proc test[T: object](param: T): bool = true
    doAssert test(A[int]()) == false
  block:
    proc test[J:int;H: A[J]; T: B[H]](param: T): bool = false
    proc test[H;T:A[H]](param: B[T]): bool = true
    doAssert test(B[A[int]]()) == false
  block:
    proc test[J:int;H: A[J]; T: B[H]](param: T): bool = false
    proc test[T](param: B[A[T]]): bool = true
    doAssert test(B[A[int]]()) == false
  block:
    proc test[J;H: A[J];T: B[H]](param: T): bool = false
    proc test[T:int](param: B[A[T]]): bool = true
    doAssert test(B[A[int]]()) == true
  block:
    proc test[H:int;T: B[A[H]]](param: T): bool = false
    proc test[T](param: B[A[T]]): bool = true
    doAssert test(B[A[int]]()) == false
  block:
    proc test[H:int;T: B[A[H]]](param: T): bool = false
    proc test[T](param: B[A[T]]): bool = true
    doAssert test(B[A[int]]()) == false
  block:
    proc test[H;T: B[A[H]]](param: T): bool = false
    proc test[T: int](param: B[A[T]]): bool = true
    doAssert test(B[A[int]]()) == true
  block:
    proc test[H: int;T: A[H]](param: B[T]): bool = false
    proc test[T](param: B[A[T]]): bool = true
    doAssert test(B[A[int]]()) == false
  block:
    proc test[T](param: T): bool = false
    proc test(param: B): bool = true
    doAssert test(B[A[int]]()) == true
  block:
    proc test[T: C](param: T): bool = false
    proc test(param: object): bool = true
    doAssert test(C()) == false
  block:
    proc test[T: C](param: A[T]): bool = false
    proc test[T: object](param: A[T]): bool = true
    doAssert test(A[C]()) == false
