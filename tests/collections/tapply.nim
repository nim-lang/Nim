var x = @[1, 2, 3]
x.apply(proc(x: var int) = x = x+10)
x.apply(proc(x: int): int = x+100)
doAssert x == @[111, 112, 113]
