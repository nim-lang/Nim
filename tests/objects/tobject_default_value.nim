discard """
  matrix: "-d:nimPreviewRangeDefault; -d:nimPreviewRangeDefault --warningAsError:ProveInit --mm:orc"
  targets: "c cpp js"
"""

import times

type
  Guess = object
    poi: DateTime

  GuessDistinct = distinct Guess

block:
  var x: Guess
  discard Guess()

  var y: GuessDistinct

  discard y

  discard GuessDistinct(x)


import mobject_default_value

block:
  let x = Default()
  doAssert x.se == 0'i32
# echo Default(poi: 12)
# echo Default(poi: 17)

# echo NonDefault(poi: 77)

block:
  var x: Default
  doAssert x.se == 0'i32

type
  ObjectBase = object of RootObj
    value = 12

  ObjectBaseDistinct = distinct ObjectBase

  DinstinctInObject = object
    data: ObjectBaseDistinct

  Object = object of ObjectBase
    time: float = 1.2
    date: int
    scale: range[1..10]

  Object2 = object
    name: Object

  Object3 = object
    obj: Object2

  # ObjectTuple = tuple
  #   base: ObjectBase
  #   typ: int
  #   obj: Object

  # TupleInObject = object
  #   size = 777
  #   data: ObjectTuple

  Ref = ref object of ObjectBase

  RefInt = ref object of Ref
    data = 73

  Ref2 = ref object of ObjectBase

  RefInt2 = ref object of Ref
    data = 73

var t {.threadvar.}: Default
# var m1, m2 {.threadvar.}: Default

block:
  doAssert t.se == 0'i32

block:
  type
    Color = enum
      Red, Blue, Yellow
  
  type
    ObjectVarint3 = object # fixme it doesn't work with static
      case kind: Color = Blue
      of Red:
        data1: int = 10
      of Blue:
        case name: Color = Blue
        of Blue:
          go = 12
        else:
          temp = 66
        fill2 = "123"
        cry: float
      of Yellow:
        time3 = 1.8'f32
        him: int
  block:
    proc check: ObjectVarint3 =
      discard
    var x = check()
    doAssert x.kind == Blue
    doAssert x.name == Blue
    doAssert x.go == 12

  block:
    var x: ObjectVarint3
    doAssert x.kind == Blue
    doAssert x.name == Blue
    doAssert x.go == 12

  block:
    var x = ObjectVarint3(kind: Blue, name: Red, temp: 99)
    doAssert x.kind == Blue
    doAssert x.name == Red
    doAssert x.temp == 99

block:
  var x: Ref
  new(x)
  doAssert x.value == 12, "Ref.value = " & $x.value

  var y: RefInt
  new(y)
  doAssert y.value == 12
  doAssert y.data == 73

block:
  var x: Ref2
  new(x, proc (x: Ref2) {.nimcall.} = discard "call Ref")
  doAssert x.value == 12, "Ref.value = " & $x.value

  proc call(x: RefInt2) =
    discard "call RefInt"

  var y: RefInt2
  new(y, call)
  doAssert y.value == 12
  doAssert y.data == 73

template main =
  block: # bug #16744
    type
      R = range[1..10]
      Obj = object
        r: R

    var
      rVal: R  # Works fine
      objVal: Obj

    doAssert objVal.r == 1

  block: # bug #3608
    type
      abc = ref object
        w: range[2..100]

    proc createABC(): abc =
      new(result)
      result.w = 20

    doAssert createABC().w == 20
  
  block:
    var x: ObjectBase
    doAssert x.value == 12
    let y = default(ObjectBase)
    doAssert y.value == 12

    proc hello(): ObjectBase =
      discard

    let z = hello()
    doAssert z.value == 12

  block:
    var x: ObjectBaseDistinct
    doAssert ObjectBase(x).value == 12
    let y = default(ObjectBaseDistinct)
    doAssert ObjectBase(y).value == 12

    proc hello(): ObjectBaseDistinct =
      discard

    let z = hello()
    doAssert ObjectBase(z).value == 12

  block:
    var x: DinstinctInObject

    doAssert ObjectBase(x.data).value == 12

  block:
    var x: Object
    doAssert x.value == 12
    doAssert x.time == 1.2
    doAssert x.scale == 1

    proc hello(): Object =
      var dummy = 1
      dummy += 18

    let h1 = hello()
    doAssert h1.value == 12
    doAssert h1.time == 1.2
    doAssert h1.scale == 1

    let y = default(Object)
    doAssert y.value == 12
    doAssert y.time == 1.2
    doAssert y.scale == 1

    var x1, x2, x3: Object
    doAssert x1.value == 12
    doAssert x1.time == 1.2
    doAssert x1.scale == 1
    doAssert x2.value == 12
    doAssert x2.time == 1.2
    doAssert x2.scale == 1
    doAssert x3.value == 12
    doAssert x3.time == 1.2
    doAssert x3.scale == 1

  block:
    var x: Object2
    doAssert x.name.value == 12
    doAssert x.name.time == 1.2
    doAssert x.name.scale == 1

  block:
    var x: Object3
    doAssert x.obj.name.value == 12
    doAssert x.obj.name.time == 1.2
    doAssert x.obj.name.scale == 1

  when nimvm:
    discard "fixme"
  else:
    when defined(gcArc) or defined(gcOrc):
      block: #seq
        var x = newSeq[Object](10)
        let y = x[0]
        doAssert y.value == 12
        doAssert y.time == 1.2
        doAssert y.scale == 1

      block:
        var x: seq[Object]
        setLen(x, 5)
        let y = x[^1]
        doAssert y.value == 12
        doAssert y.time == 1.2
        doAssert y.scale == 1

  block: # array
    var x: array[10, Object]
    let y = x[0]
    doAssert y.value == 12
    doAssert y.time == 1.2
    doAssert y.scale == 1

  block: # array
    var x {.noinit.}: array[10, Object]
    discard x

  # block: # tuple
  #   var x: ObjectTuple
  #   doAssert x.base.value == 12
  #   doAssert x.typ == 0
  #   doAssert x.obj.time == 1.2
  #   doAssert x.obj.date == 0
  #   doAssert x.obj.scale == 1
  #   doAssert x.obj.value == 12

  # block: # tuple in object
  #   var x: TupleInObject
  #   doAssert x.data.base.value == 12
  #   doAssert x.data.typ == 0
  #   doAssert x.data.obj.time == 1.2
  #   doAssert x.data.obj.date == 0
  #   doAssert x.data.obj.scale == 1
  #   doAssert x.data.obj.value == 12
  #   doAssert x.size == 777

  type
    ObjectArray = object
      data: array[10, Object]

  block:
    var x: ObjectArray
    let y = x.data[0]
    doAssert y.value == 12
    doAssert y.time == 1.2
    doAssert y.scale == 1


  block:
    var x: PrellDeque[int]
    doAssert x.pendingTasks == 0

  type
    Color = enum
      Red, Blue, Yellow

    ObjectVarint = object
      case kind: Color
      of Red:
        data: int = 10
      of Blue:
        fill = "123"
      of Yellow:
        time = 1.8'f32

    ObjectVarint1 = object
      case kind: Color = Blue
      of Red:
        data1: int = 10
      of Blue:
        fill2 = "123"
        cry: float
      of Yellow:
        time3 = 1.8'f32
        him: int

  block:
    var x = ObjectVarint(kind: Red)
    doAssert x.kind == Red
    doAssert x.data == 10

  block:
    var x = ObjectVarint(kind: Blue)
    doAssert x.kind == Blue
    doAssert x.fill == "123"

  block:
    var x = ObjectVarint(kind: Yellow)
    doAssert x.kind == Yellow
    doAssert typeof(x.time) is float32

  block:
    var x: ObjectVarint1
    doAssert x.kind == Blue
    doAssert x.fill2 == "123"
    x.cry = 326

  type
    ObjectVarint2 = object
      case kind: Color
      of Red:
        data: int = 10
      of Blue:
        fill = "123"
      of Yellow:
        time = 1.8'f32

  block:
    var x = ObjectVarint2(kind: Blue)
    doAssert x.fill == "123"


proc main1 =
  var my = @[1, 2, 3, 4, 5]
  my.setLen(0)
  my.setLen(5)
  doAssert my == @[0, 0, 0, 0, 0]

proc main2 =
  var my = "hello"
  my.setLen(0)
  my.setLen(5)
  doAssert $(@my) == """@['\x00', '\x00', '\x00', '\x00', '\x00']"""

when defined(gcArc) or defined(gcOrc):
  main1()
  main2()

static: main()
main()
