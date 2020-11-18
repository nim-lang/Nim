block:
  if false:
    discard cast[ptr int](nil)[]

block:
  if false:
    var x: ref int = nil
    echo cast[ptr int](x)[]
