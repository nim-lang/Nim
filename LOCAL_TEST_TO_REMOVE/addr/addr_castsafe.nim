proc xx(x: var string) =
  echo x.addr.repr

proc yy() {.memSafe.}=
  var y = "yy"
  echo y
  {.cast(memSafe).}:
    xx(y)

yy()
