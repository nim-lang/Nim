
const
  debug = true

template log(msg: string) =
  if debug:
    echo msg
var
  x = 1
  y = 2

log("x: " & $x & ", y: " & $y)
