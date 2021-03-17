import std/sets

type
  Diff*[T] = object
    data: T

proc test*[T](diff: Diff[T]) =
  var bPopular = initHashSet[T]()
  for element in bPopular.items():
    echo element

