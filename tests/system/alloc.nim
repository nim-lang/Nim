var x: ptr int

x = cast[ptr int](alloc(7))
assert x != nil

x = alloc(int, 3)
assert x != nil
x.dealloc()

x = alloc0(int, 4)
assert cast[ptr array[4, int]](x)[0] == 0
assert cast[ptr array[4, int]](x)[1] == 0
assert cast[ptr array[4, int]](x)[2] == 0
assert cast[ptr array[4, int]](x)[3] == 0

x = cast[ptr int](x.realloc(2))
assert x != nil

x = x.resize(4)
assert x != nil
x.dealloc()

x = cast[ptr int](allocShared(100))
assert x != nil
deallocShared(x)

x = allocShared(int, 3)
assert x != nil
x.deallocShared()

x = allocShared0(int, 3)
assert x != nil
assert cast[ptr array[3, int]](x)[0] == 0
assert cast[ptr array[3, int]](x)[1] == 0
assert cast[ptr array[3, int]](x)[2] == 0

x = cast[ptr int](reallocShared(x, 2))
assert x != nil

x = resize(x, 12)
assert x != nil

x = resizeShared(x, 1)
assert x != nil
x.deallocShared()
