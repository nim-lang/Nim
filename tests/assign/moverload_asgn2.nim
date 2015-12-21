type
  Concrete* = object
    a*, b*: string
    rc*: int # refcount

proc `=`(d: var Concrete; src: Concrete) =
  shallowCopy(d.a, src.a)
  shallowCopy(d.b, src.b)
  dec d.rc
  d.rc = src.rc + 1
