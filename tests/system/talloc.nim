var x: ptr int

x = cast[ptr int](alloc(7))
assert x != nil
x = cast[ptr int](x.realloc(2))
assert x != nil
x.dealloc()

x = createU(int, 3)
assert x != nil
x.dealloc()

x = create(int, 4)
assert cast[ptr array[4, int]](x)[0] == 0
assert cast[ptr array[4, int]](x)[1] == 0
assert cast[ptr array[4, int]](x)[2] == 0
assert cast[ptr array[4, int]](x)[3] == 0

x = x.resize(4)
assert x != nil
x.dealloc()

x = cast[ptr int](allocShared(100))
assert x != nil
deallocShared(x)

x = createSharedU(int, 3)
assert x != nil
x.deallocShared()

x = createShared(int, 3)
assert x != nil
assert cast[ptr array[3, int]](x)[0] == 0
assert cast[ptr array[3, int]](x)[1] == 0
assert cast[ptr array[3, int]](x)[2] == 0

assert x != nil
x = cast[ptr int](x.resizeShared(2))
assert x != nil
x.deallocShared()

x = create(int, 10)
assert x != nil
x = x.resize(12)
assert x != nil
x.dealloc()

x = createShared(int, 1)
assert x != nil
x = x.resizeShared(1)
assert x != nil
x.deallocShared()

x = cast[ptr int](alloc0(125 shl 23))
dealloc(x)
x = cast[ptr int](alloc0(126 shl 23))
dealloc(x)
