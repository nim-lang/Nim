discard """
  nimout: "int\nint"
  output: 15
"""

import typetraits

type
  Iterable[T] = concept x
    for value in x:
      type(value) is T

proc sum*[T](iter: Iterable[T]): T =
  static: echo T.name
  for element in iter:
    static: echo element.type.name
    result += element

echo sum([1, 2, 3, 4, 5])

