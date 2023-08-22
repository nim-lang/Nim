discard """
  output: '''123
1234
123
1234
12345
123456
'''
"""

# Test simple type
var a = 123
proc getA(): var int = a

echo getA()

getA() = 1234
echo getA()


# Test object type
type Foo = object
    a: int
var f: Foo
f.a = 123
proc getF(): var Foo = f
echo getF().a
getF().a = 1234
echo getF().a
getF() = Foo(a: 12345)
echo getF().a
(addr getF())[] = Foo(a: 123456)
echo getF().a


block: # #13848
  template fun() =
    block:
      var m = 1

      proc identity(o: var int): var int =
        result = o
        result += 5

      identity(m) += 3
      doAssert m == 5+4

    block:
      var m = 10
      proc identity2(o: var int): var int =
        result = m
        result += 100

      var ignored = 27
      identity2(ignored) += 7
      doAssert m == 10 + 100 + 7

    block:
      iterator test3(o: var int): var int = yield o
      var m = 1
      for m2 in test3(m): m2+=3
      doAssert m == 4

  static: fun()
  fun()

  template fun2() =
    block:
      var m = 1
      var m2 = 1
      iterator test3(o: var int): (var int, var int) =
        yield (o, m2)

      for ti in test3(m):
        ti[0]+=3
        ti[1]+=4

      doAssert (m, m2) == (4, 5)
  fun2()
  # static: fun2() # BUG: Error: attempt to access a nil address kind: rkInt

  template fun3() =
    block:
      proc test4[T1](o: var T1): var int = o[1]
      block:
        var m = @[1,2]
        test4(m) += 10
        doAssert m[1] == 2+10
      block:
        var m = [1,2]
        test4(m) += 10
        doAssert m[1] == 2+10
      block:
        var m = (1, 2)
        test4(m) += 10
        doAssert m[1] == 2+10

      proc test5[T1](o: var T1): var int = o.x
      block:
        type Foo = object
          x: int
        var m = Foo(x: 2)
        test5(m) += 10
        doAssert m.x == 2+10
      block:
        type Foo = ref object
          x: int
        var m = Foo(x: 2)
        test5(m) += 10
        doAssert m.x == 2+10

      proc test6[T1](o: T1): var int = o.x
      block:
        type Foo = ref object
          x: int
        var m = Foo(x: 2)
        test6(m) += 10
        doAssert m.x == 2+10

  fun3()
  static: fun3()

  when false:
    # BUG:
    # c: SIGSEGV
    # cpp: error: call to implicitly-deleted default constructor of 'tyTuple__ILZebuYefUeQLAzY85QkHA'
    proc test7[T](o: var T): (var int,) =
      (o[1], )
    var m = @[1,2]
    test7(m)[0] += 10

block:
  # example from #13848
  type
    MyType[T] = object
      a,b: T
    MyTypeAlias = MyType[float32]

  var m: MyTypeAlias
  proc identity(o: var MyTypeAlias): var MyTypeAlias = o
  discard identity(m)
