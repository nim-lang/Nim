import ./c

proc p*(): D =
  let c = M[uint64](data: @[0], indices: [1])
  result = D(g: c)