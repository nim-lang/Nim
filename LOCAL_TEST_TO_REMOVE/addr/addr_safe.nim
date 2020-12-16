proc xx(x: var string) =
  echo x.addr.repr

proc yy() {.memsafe.}=
  var y = "yy"
  echo y
  xx(y)

yy()
