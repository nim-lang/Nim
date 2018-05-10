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