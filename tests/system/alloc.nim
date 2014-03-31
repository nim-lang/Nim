var x: ptr int

x = cast[ptr int](alloc(7))
assert x != nil
x = cast[ptr int](x.realloc(2))
assert x != nil
x.dealloc()

x = createU(int, 3)
assert x != nil
x.free()

x = create(int, 4)
assert cast[ptr array[4, int]](x)[0] == 0
assert cast[ptr array[4, int]](x)[1] == 0
assert cast[ptr array[4, int]](x)[2] == 0
assert cast[ptr array[4, int]](x)[3] == 0

x = x.resize(4)
assert x != nil
x.free()

x = cast[ptr int](allocShared(100))
assert x != nil
deallocShared(x)

x = createSharedU(int, 3)
assert x != nil
x.freeShared()

x = createShared(int, 3)
assert x != nil
assert cast[ptr array[3, int]](x)[0] == 0
assert cast[ptr array[3, int]](x)[1] == 0
assert cast[ptr array[3, int]](x)[2] == 0

assert x != nil
x = cast[ptr int](x.resizeShared(2))
assert x != nil
x.freeShared()

x = create(int, 10)
assert x != nil
x = x.resize(12)
assert x != nil
x.dealloc()

x = createShared(int, 1)
assert x != nil
x = x.resizeShared(1)
assert x != nil
x.freeShared()
