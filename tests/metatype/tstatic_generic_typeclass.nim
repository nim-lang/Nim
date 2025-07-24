type MyThing[T: static int] = object
  when T == 300:
    a: int

var a = MyThing[300]()
proc doThing(myThing: MyThing): string = $myThing
proc doOtherThing[T](myThing: MyThing[T]): string = $myThing
assert doThing(a) == $a
assert doThing(MyThing[0]()) == $MyThing[0]()
assert doOtherThing(a) == "(a: 0)"

type
  Backend* = enum
    Cpu,
    Cuda

  Tensor*[B: static[Backend]; T] = object
    shape: seq[int]
    strides: seq[int]
    offset: int
    when B == Backend.Cpu:
      data: seq[T]
    else:
      data_ptr: ptr T

template shape*(t: Tensor): seq[int] =
  t.shape


assert Tensor[Cpu, int]().shape == @[]
