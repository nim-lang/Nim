import std/atomics

type
  Pledge = object
    fulfilled: Atomic[bool]

var y = Pledge()
echo y.fulfilled.repr
y.fulfilled.store(true)
echo y.fulfilled.repr
doAssert y.fulfilled.load == true
# var x: Pledge
# echo x.repr
