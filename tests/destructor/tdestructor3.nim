discard """
  output: '''assign
destroy
destroy
5
123
destroy Foo: 5
destroy Foo: 123'''
joinable: false
"""

# bug #2821

type T = object

proc `=`(lhs: var T, rhs: T) =
    echo "assign"

proc `=destroy`(v: var T) =
    echo "destroy"

proc use(x: T) = discard

proc usedToBeBlock =
    var v1 : T
    var v2 : T = v1
    use v1

usedToBeBlock()

# bug #1632

type
  Foo = object of RootObj
    x: int

proc `=destroy`(a: var Foo) =
  echo "destroy Foo: " & $a.x

template toFooPtr(a: int{lit}): ptr Foo =
  var temp = Foo(x:a)
  temp.addr

proc test(a: ptr Foo) =
  echo a[].x

proc main =
  test(toFooPtr(5))
  test(toFooPtr(123))

main()
