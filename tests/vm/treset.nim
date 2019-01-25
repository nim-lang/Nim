static:
  type Obj = object
    field: int
  var o = Obj(field: 1)
  reset(o)
  doAssert o.field == 0

static:
  var i = 2
  reset(i)
  doAssert i == 0

static:
  var i = new int
  reset(i)
  doAssert i.isNil

static:
  var s = @[1, 2, 3]
  reset(s)
  doAssert s == @[]

static:
  proc f() =
    var i = 2
    reset(i)
    doAssert i == 0
  f()