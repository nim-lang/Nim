#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.

## The ``concepts`` module contains implementations of standard concepts used
## across Nim's standard library.

type
  Iterable*[T] = concept x
    ## This concept matches collection types which can be iterated via `items`
    ## iterator.
    for value in items(x):
      type(value) is T

  IterableLen*[T] = concept x
    ## This concept matches collection types which can be iterated via `items`
    ## iterator and have `len` procedure returning an `Ordinal` type
    ## representing the count of the elements in the collection.
    ## 
    ## See also:
    ## * `Iterable concept <#Iterable[T]>`_
    len(x) is Ordinal
    for value in x:
      type(value) is T

when isMainModule:
  proc sum[T](iter: IterableLen[T]): T =
    for element in iter:
      result += element

  doAssert sum([1, 2, 3, 4, 5]) == 15
