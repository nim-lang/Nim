discard """
  output: "true"
"""

import future

type
  FilterMixin*[T] = ref object
    test*:      (T) -> bool
    trans*:     (T) -> T

  SeqGen*[T] = ref object
    fil*:     FilterMixin[T]
  
  WithFilter[T] = concept a
    a.fil is FilterMixin[T]

proc test*[T](a: WithFilter[T]): (T) -> bool =
  a.fil.test

var s = SeqGen[int](fil: FilterMixin[int](test: nil, trans: nil))
echo s.test() == nil

