# bug #17437 invalid object construction should result in error

type
  V = ref object
    x, y: int

proc m =
  var x = 12
  var y = 1
  var v = V(x: x, y)

m()
