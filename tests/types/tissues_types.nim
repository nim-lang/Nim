discard """
  output: '''true
true
true
true
ptr Foo
(member: "hello world")
(member: 123.456)
(member: "hello world", x: ...)
(member: 123.456, x: ...)
0
false
'''
joinable: false
"""
# not joinable because it causes out of memory with --gc:boehm
import typetraits

block t1252:
  echo float32 isnot float64
  echo float32 isnot float
  echo int32 isnot int64
  echo int32 isnot int

block t5640:
  type
    vecBase[I: static[int]] = distinct array[I, float32]
    vec2 = vecBase[2]

  var v = vec2([0.0'f32, 0.0'f32])

block t5648:
  type Foo = object
    bar: int

  proc main() =
    var f = create(Foo)
    f.bar = 3
    echo f.type.name

    discard realloc(f, 0)

    var g = Foo()
    g.bar = 3

  var
    mainPtr1: pointer = main
    mainPtr2 = pointer(main)
    mainPtr3 = cast[pointer](main)

  doAssert mainPtr1 == mainPtr2 and mainPtr2 == mainPtr3

  main()

block t7581:
  discard int -1

block t7905:
  template foobar(arg: typed): untyped =
    type
      MyType = object
        member: type(arg)

    var myVar: MyType
    myVar.member = arg
    echo myVar

  foobar("hello world")
  foobar(123.456'f64)

  template foobarRec(arg: typed): untyped =
    type
      MyType = object
        member: type(arg)
        x: ref MyType

    var myVar: MyType
    myVar.member = arg
    echo myVar

  foobarRec("hello world")
  foobarRec(123.456'f64)

# bug #5170

when true:
  type Foo = object
    bar: bool

  type Bar = object
    sameBody: string

  var b0: Bar
  b0.sameBody = "abc"

block:
  type Foo = object
    baz: int

  type Bar = object
    sameBody: string

  var b1: Bar
  b1.sameBody = "def"

  var f2: Foo
  echo f2.baz

var f1: Foo
echo f1.bar
