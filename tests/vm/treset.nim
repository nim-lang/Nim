discard """
  output: '''0'''
"""
static:
  type Obj = object
    field: int
  var o = Obj(field: 1)
  reset(o)
  doAssert o.field == 0

  var x = 4
  reset(x)
  doAssert x == 0

static:
  type ObjB = object
    field: int
  var o = ObjB(field: 1)
  o = default(ObjB)
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

proc main =
  var y = [1, 2, 3, 4]
  y = default(array[4, int])
  for a in y: doAssert(a == 0)

  var x = 4
  x = default(int)
  echo x

main()
