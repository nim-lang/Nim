type
  Vector = object
    a: int = 999
    b, c: int

block: # positional construction
  ## It specifies all the unnamed fields
  var x = Vector(1, 2, 3)
  doAssert x.b == 2

block:
  ## unnamed fields can be mixed with named fields
  block:
    var x = Vector(a: 1, 2, 3)
    doAssert x.c == 3

  block:
    var x = Vector(1, b: 2, 3)
    doAssert x.c == 3

  block:
    var x = Vector(1, 2, c: 3)
    doAssert x.c == 3

block:
  ## Object variants support unnamed fields for tags, which should be known at the compile time.
  type
    Color = enum
      Red, Blue, Yellow
    Factor = object
      id: int
      case flag: Color
      of Red:
        num: int
      of Blue, Yellow:
        done: bool
      name: string

  block:
    var x = Factor(1, Red, 2, "1314")
    doAssert x.num == 2

  block:
    var x = Factor(1, Blue, true, "1314")
    doAssert x.done == true

  block:
    var x = Factor(1, Yellow, false, "1314")
    doAssert x.done == false


  type
    Ciao = object
      id: int
      case flag: bool = false
      of true:
        num: int
      of false:
        done: bool
      name: string

  block:
    var x = Ciao(12, false, false, "123")
    doAssert x.done == false

  block:
    var x = Ciao(12, flag: true, 1, "123")
    doAssert x.num == 1
