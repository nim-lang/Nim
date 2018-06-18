static:
  var
    a: ref string
    b: ref string
  new a

  a[] = "Hello world"
  b = a

  b[5] = 'c'
  doAssert a[] == "Hellocworld"
  doAssert b[] == "Hellocworld"

static:
  type Obj = object
    field: int
  var s = newSeq[Obj](1)
  var o = Obj()
  s[0] = o
  o.field = 2
  doAssert s[0].field == 0