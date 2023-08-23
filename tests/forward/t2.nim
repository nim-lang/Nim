{.experimental: "noforwardDecl".}

proc foo(x: int)

proc bar(x: int) =
  var s = 1
  inc s, x
  foo(s)


proc foo(x: int) =
  echo x

bar(999)