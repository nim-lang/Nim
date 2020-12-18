static: echo "###############################"
# proc addr[T](x: var T): ptr T {.memUnsafe.} =
#   system.addr(x)

proc xx(x: var string) =
  echo repr(x.addr)

proc yy() =
  var y = "yy"
  echo y
  xx(y)

yy()
