discard """
  line: 12
  errormsg: "instantiate 'notConcrete' explicitely"
"""

proc wrap[T]() =
  proc notConcrete[T](x, y: int): int =
    var dummy: T
    result = x - y

  var x: proc (x, y: T): int
  x = notConcrete
  

wrap[int]()

