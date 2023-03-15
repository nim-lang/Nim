type MyThing[T: static int] = object
  when T == 300:
    a: int

var a = MyThing[300]()
proc doThing(myThing: MyThing): string = $myThing
assert doThing(a) == $a
assert doThing(MyThing[0]()) == $MyThing[0]()


type
  Backend* = enum
    Cpu

  Tensor*[B: static[Backend]; T] = object
    shape: seq[int]
    strides: seq[int]
    offset: int
    data: seq[T]

template shape*(t: Tensor): seq[int] =
  t.shape
