discard """
  output: '''123
1234
123
1234
12345
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


block: # #13848
  template fun() =
    var m = 1
    var m2 = 10

    proc identity(o: var int): var int =
      result = o
      result += 5

    proc identity2(o: var int): var int =
      result = m2
      result += 100

    identity(m) += 3
    doAssert m == 5+4

    var ignored = 27
    identity2(ignored) += 7
    doAssert m2 == 10 + 100 + 7

  static: fun()
  fun()

block:
  # example from #13848
  type
    MyType[T] = object
      a,b: T
    MyTypeAlias = MyType[float32]

  var m: MyTypeAlias
  proc identity(o: var MyTypeAlias): var MyTypeAlias = o
  discard identity(m)
