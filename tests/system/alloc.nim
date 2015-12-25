var x: ptr int

x = cast[ptr int](alloc(7))
doAssert x != nil
x = cast[ptr int](x.realloc(2))
doAssert x != nil
x.dealloc()

x = createU(int, 3)
doAssert x != nil
x.free()

x = create(int, 4)
doAssert cast[ptr array[4, int]](x)[0] == 0
doAssert cast[ptr array[4, int]](x)[1] == 0
doAssert cast[ptr array[4, int]](x)[2] == 0
doAssert cast[ptr array[4, int]](x)[3] == 0

x = x.resize(4)
doAssert x != nil
x.free()

x = cast[ptr int](allocShared(100))
doAssert x != nil
deallocShared(x)

x = createSharedU(int, 3)
doAssert x != nil
x.freeShared()

x = createShared(int, 3)
doAssert x != nil
doAssert cast[ptr array[3, int]](x)[0] == 0
doAssert cast[ptr array[3, int]](x)[1] == 0
doAssert cast[ptr array[3, int]](x)[2] == 0

doAssert x != nil
x = cast[ptr int](x.resizeShared(2))
doAssert x != nil
x.freeShared()

x = create(int, 10)
doAssert x != nil
x = x.resize(12)
doAssert x != nil
x.dealloc()

x = createShared(int, 1)
doAssert x != nil
x = x.resizeShared(1)
doAssert x != nil
x.freeShared()
