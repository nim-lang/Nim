discard """
action: compile
"""

type
  SomeObj[T] = object

template useSomeObj[T]() =
  var retObj: SomeObj[T]

useSomeObj[void]()
useSomeObj[int]()


type
  Data*[T] = object
    x: T

template test*[T](xxx: T) =
  let data = Data[T](x: xxx)

test(1)
