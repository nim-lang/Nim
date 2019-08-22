discard """
  output: "2.0"
"""

{.warning[TypelessParam]: off.}

import sugar

# bug #3329

proc foldRight[T,U](lst: seq[T], v: U, f: (T, U) -> U): U =
  result = v
  for x in lst:
    result = f(x, result)

proc mean[T: SomeNumber](xs: seq[T]): T =
  xs.foldRight(0.T, (xBAZ: auto, yBAZ: auto) => xBAZ + yBAZ) / T(xs.len)

when true:
  let x = mean(@[1.float, 2, 3])
  echo x

