
# bug #1337

template someIt(a, pred): untyped =
  var it {.inject.} = 0
  pred

proc aProc(n: auto) =
  n.someIt(echo(it))

aProc(89)
