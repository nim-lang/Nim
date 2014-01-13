discard """
  output: '''666
666'''
"""

# test the new generic converters:

type
  TFoo2[T] = object
    x: T

  TFoo[T] = object
    data: array[0..100, T]

converter toFoo[T](a: TFoo2[T]): TFoo[T] =
  result.data[0] = a.x

proc p(a: TFoo[int]) =
  echo a.data[0]

proc q[T](a: TFoo[T]) =
  echo a.data[0]


var
  aa: TFoo2[int]
aa.x = 666

p aa
q aa
