discard """
  output: '''42'''
"""

type
  Data[T] = object
    value: T
  Shared[T] = ptr Data[T]
  Holder = object
    data: Shared[int]

proc init(h: var Holder, d: ptr Data[int]) =
  h = Holder(data: Shared(d))

var h: Holder
var d = Data[int](value: 42)
init(h, addr d)
echo h.data.value
