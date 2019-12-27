discard """
  errormsg: "instantiate 'notConcrete' explicitly"
  line: 12
  disabled: "true"
"""

proc wrap[T]() =
  proc notConcrete[T](x, y: int): int =
    var dummy: T
    result = x - y

  var x: proc (x, y: T): int
  x = notConcrete


wrap[int]()
