discard """
  output: "true\ntrue"
"""

type
  TFooContainer[T] = object

  TContainer[T] = concept var c
    foo(c, T)

proc foo[T](c: var TFooContainer[T], val: T) =
  discard

proc bar(c: var TContainer) =
  discard

var fooContainer: TFooContainer[int]
echo fooContainer is TFooContainer # true.
echo fooContainer is TFooContainer[int] # true.
fooContainer.bar()

