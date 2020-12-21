discard """
action: reject
"""
type
  XX = object
    a:  int
    b:  float
    c:  byte

proc xx*() : ptr XX =
  echo "xx"
  {.cast(memSafe).}:
    var x = alloc0(sizeof(XX))
    result = cast[ptr XX](x)

proc yy(x: ptr XX) =
  echo "yy"
  x.a = 1
  x.b = 22.2
  x.c = 0xAF
  echo x[]

proc zz() {.memSafe.} =
  var x = xx()
  yy(x)
  dealloc(x)

zz()
