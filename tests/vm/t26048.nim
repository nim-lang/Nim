# issue #26048, `$` declarations must not leak from `when nimvm`

type U = object

when nimvm:
  proc `$`(_: U): string = "s"

var n: U
doAssert $n != "s"
