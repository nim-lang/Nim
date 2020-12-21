discard """
action: compile
"""
type
  XX = object
    a:  int
    b:  float
    c:  byte

  PXX = ptr XX

proc xx() : PXX =
  echo "xx"
  {.cast(memSafe).}:
    var x = alloc0(sizeof(XX))
    result = cast[ptr XX](x)

proc yy(x: PXX) =
  echo "yy"
  x.a = 1
  x.b = 22.2
  x.c = 0xAF
  # Ok because . syntax
  echo x.repr

proc zz() {.memSafe.} =
  var x = xx()
  yy(x)
  dealloc(x)


zz()
